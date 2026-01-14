/*
 * CHMPX
 *
 * Copyright 2015 Yahoo Japan Corporation.
 *
 * CHMPX is inprocess data exchange by MQ with consistent hashing.
 * CHMPX is made for the purpose of the construction of
 * original messaging system and the offer of the client
 * library.
 * CHMPX transfers messages between the client and the server/
 * slave. CHMPX based servers are dispersed by consistent
 * hashing and are automatically laid out. As a result, it
 * provides a high performance, a high scalability.
 *
 * For the full copyright and license information, please view
 * the license file that was distributed with this source code.
 *
 * AUTHOR:   Taku Ishihara
 * CREATE:   Tue Oct 6 2015
 * REVISION:
 *
 */

#include "chmpx_node.h"
#include "chmpx_node_async.h"

using namespace std;

//---------------------------------------------------------
// Emitter
//---------------------------------------------------------
#define	EMITTER_POS_INITIALIZEONSERVER			(0)
#define	EMITTER_POS_INITIALIZEONSLAVE			(EMITTER_POS_INITIALIZEONSERVER	+ 1)
#define	EMITTER_POS_OPEN						(EMITTER_POS_INITIALIZEONSLAVE	+ 1)
#define	EMITTER_POS_CLOSE						(EMITTER_POS_OPEN				+ 1)
#define	EMITTER_POS_SEND						(EMITTER_POS_CLOSE				+ 1)
#define	EMITTER_POS_BROADCAST					(EMITTER_POS_SEND				+ 1)
#define	EMITTER_POS_REPLY						(EMITTER_POS_BROADCAST			+ 1)
#define	EMITTER_POS_RECEIVE						(EMITTER_POS_REPLY				+ 1)

const char*	stc_emitters[] = {
	"initializeOnServer",
	"initializeOnSlave",
	"open",
	"close",
	"send",
	"broadcast",
	"reply",
	"receive",
	NULL
};

inline const char* GetNormalizationEmitter(const char* emitter)
{
	if(!emitter){
		return nullptr;
	}
	for(const char** ptmp = &stc_emitters[0]; ptmp && *ptmp; ++ptmp){
		if(0 == strcasecmp(*ptmp, emitter)){
			return *ptmp;
		}
	}
	return nullptr;
}

//---------------------------------------------------------
// Utility (using StackEmitCB Class)
//---------------------------------------------------------
static Napi::Value SetChmpxNodeCallback(const Napi::CallbackInfo& info, size_t pos, const char* pemitter)
{
	Napi::Env env = info.Env();

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode* obj = Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// check parameter
	if(info.Length() <= pos){
		Napi::TypeError::New(env, "No callback is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	if(!info[pos].IsFunction()){
		Napi::TypeError::New(env, "The parameter is not callback function.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Function cb = info[pos].As<Napi::Function>();

	// set
	bool result = obj->_cbs.Set(std::string(pemitter), cb);
	return Napi::Boolean::New(env, result);
}

static Napi::Value UnsetChmpxNodeCallback(const Napi::CallbackInfo& info, const char* pemitter)
{
	Napi::Env env = info.Env();

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode* obj = Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// unset
	bool result = obj->_cbs.Unset(std::string(pemitter));
	return Napi::Boolean::New(env, result);
}

//---------------------------------------------------------
// ChmpxNode Class
//---------------------------------------------------------
Napi::FunctionReference	ChmpxNode::constructor;

//---------------------------------------------------------
// ChmpxNode Methods
//---------------------------------------------------------
ChmpxNode::ChmpxNode(const Napi::CallbackInfo& info) : Napi::ObjectWrap<ChmpxNode>(info), _cbs(), _chmcntrl()
{
	// [NOTE]
	// Perhaps due to an initialization order issue, these
	// chmpx debug environment variable settings don't work.
	// So, load the environment variables and set the debug
	// mode/file settings here.
	//
	const char* chmpxdbgmode = std::getenv("CHMDBGMODE");
	const char* chmpxdbgfile = std::getenv("CHMDBGFILE");
	if(chmpxdbgmode && chmpxdbgfile){
		if(0 == strcasecmp(chmpxdbgmode, "SLT") || 0 == strcasecmp(chmpxdbgmode, "SILENT")){
			chmpx_set_debug_level_silent();
		}else if(0 == strcasecmp(chmpxdbgmode, "ERR") || 0 == strcasecmp(chmpxdbgmode, "ERROR")){
			chmpx_set_debug_level_error();
		}else if(0 == strcasecmp(chmpxdbgmode, "WARNING") || 0 == strcasecmp(chmpxdbgmode, "WARN") || 0 == strcasecmp(chmpxdbgmode, "WAN")){
			chmpx_set_debug_level_warning();
		}else if(0 == strcasecmp(chmpxdbgmode, "INFO") || 0 == strcasecmp(chmpxdbgmode, "INF") || 0 == strcasecmp(chmpxdbgmode, "MSG")){
			chmpx_set_debug_level_message();
		}else if(0 == strcasecmp(chmpxdbgmode, "DUMP") || 0 == strcasecmp(chmpxdbgmode, "DMP")){
			chmpx_set_debug_level_dump();
		}
		chmpx_set_debug_file(chmpxdbgfile);		// Ignore any errors that occur.
	}
}

ChmpxNode::~ChmpxNode()
{
	_chmcntrl.Clean();
}

void ChmpxNode::Init(Napi::Env env, Napi::Object exports)
{
	Napi::Function funcs = DefineClass(env, "ChmpxNode", {
		// DefineClass normally handles the constructor internally. Therefore, there is no need
		// to include a static wrapper New() in the class prototype, which works the same way as
		// when using NAN.
		// For reference, the following example shows how to declare New as a static method.
		// (Registration is not normally required.)
		//
		//	ChmpxNode::InstanceMethod("new", 						&ChmpxNode::New),

		// Prototype for event emitter
		ChmpxNode::InstanceMethod("on",						&ChmpxNode::On),
		ChmpxNode::InstanceMethod("onInitializeOnServer",	&ChmpxNode::OnInitializeOnServer),
		ChmpxNode::InstanceMethod("onInitializeOnSlave",	&ChmpxNode::OnInitializeOnSlave),
		ChmpxNode::InstanceMethod("onOpen",					&ChmpxNode::OnOpen),
		ChmpxNode::InstanceMethod("onClose",				&ChmpxNode::OnClose),
		ChmpxNode::InstanceMethod("onSend",					&ChmpxNode::OnSend),
		ChmpxNode::InstanceMethod("onBroadcast",			&ChmpxNode::OnBroadcast),
		ChmpxNode::InstanceMethod("onReply",				&ChmpxNode::OnReply),
		ChmpxNode::InstanceMethod("onReceive",				&ChmpxNode::OnReceive),
		ChmpxNode::InstanceMethod("off",					&ChmpxNode::Off),
		ChmpxNode::InstanceMethod("offInitializeOnServer",	&ChmpxNode::OffInitializeOnServer),
		ChmpxNode::InstanceMethod("offInitializeOnSlave",	&ChmpxNode::OffInitializeOnSlave),
		ChmpxNode::InstanceMethod("offOpen",				&ChmpxNode::OffOpen),
		ChmpxNode::InstanceMethod("offClose",				&ChmpxNode::OffClose),
		ChmpxNode::InstanceMethod("offSend",				&ChmpxNode::OffSend),
		ChmpxNode::InstanceMethod("offBroadcast",			&ChmpxNode::OffBroadcast),
		ChmpxNode::InstanceMethod("offReply",				&ChmpxNode::OffReply),
		ChmpxNode::InstanceMethod("offReceive",				&ChmpxNode::OffReceive),

		// Prototype
		ChmpxNode::InstanceMethod("initializeOnServer",		&ChmpxNode::InitializeOnServer),
		ChmpxNode::InstanceMethod("initializeOnSlave",		&ChmpxNode::InitializeOnSlave),
		ChmpxNode::InstanceMethod("send",					&ChmpxNode::Send),
		ChmpxNode::InstanceMethod("broadcast",				&ChmpxNode::Broadcast),
		ChmpxNode::InstanceMethod("receive",				&ChmpxNode::Receive),
		ChmpxNode::InstanceMethod("reply",					&ChmpxNode::Reply),
		ChmpxNode::InstanceMethod("open",					&ChmpxNode::Open),
		ChmpxNode::InstanceMethod("close",					&ChmpxNode::Close),
		ChmpxNode::InstanceMethod("isChmpxExit",			&ChmpxNode::IsChmpxExit)
	});

	constructor = Napi::Persistent(funcs);
	constructor.SuppressDestruct();

	// [NOTE]
	// do NOT do exports.Set("ChmpxNode", func) here if InitAll will return createFn.
	//
}

Napi::Value ChmpxNode::New(const Napi::CallbackInfo& info)
{
	if(info.IsConstructCall()){
		// Invoked as constructor: new ChmpxNode()
		return info.This();
	}else{
		// Invoked as plain function ChmpxNode(), turn into construct call.
		return constructor.New({});		// always no arguments
	}
}

// [NOTE]
// The logic for receiving arguments when switching to N-API has been removed.
// This is because the arguments were not used in the first place and did not
// need to be defined.
//
// NewInstance( always no argments )
Napi::Object ChmpxNode::NewInstance(Napi::Env env)
{
	Napi::EscapableHandleScope scope(env);
	Napi::Object obj = constructor.New({}).As<Napi::Object>();
	return scope.Escape(napi_value(obj)).ToObject();
}

Napi::Object ChmpxNode::GetInstance(const Napi::CallbackInfo& info)
{
	if(0 < info.Length()){
		return ChmpxNode::constructor.New({info[0]});
	}else{
		return ChmpxNode::constructor.New({});
	}
}

/**
 * @mainpage chmpx_nodejs
 */

/// \defgroup nodejs_methods	the methods for using from node.js
//@{

/**
 * @memberof ChmpxNode
 * @fn void\
 * On(\
 * 	String	emitter\
 * 	, Callback cbfunc\
 * )
 * @brief	set callback handling
 *
 * @param[in] emitter			Specify emitter name
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::On(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No handle emitter name is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}else if(info.Length() < 2){
		Napi::TypeError::New(env, "No callback is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// check emitter name
	std::string emitter  = info[0].ToString().Utf8Value();
	const char* pemitter = GetNormalizationEmitter(emitter.c_str());
	if(!pemitter){
		std::string	msg	= "Unknown ";
		msg				+= emitter;
		msg				+= " emitter";
		Napi::TypeError::New(env, msg).ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// add callback
	return SetChmpxNodeCallback(info, 1, pemitter);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnInitializeOnServer(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnInitializeOnServer(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnInitializeOnSlave(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnInitializeOnSlave(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnOpen(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnOpen(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_OPEN]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnClose(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnClose(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_CLOSE]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnSend(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnSend(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_SEND]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnBroadcast(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnBroadcast(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_BROADCAST]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnReply(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnReply(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_REPLY]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OnReceive(\
 * 	Callback cbfunc\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @param[in] cbfunc			callback function.
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OnReceive(const Napi::CallbackInfo& info)
{
	return SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_RECEIVE]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * Off(\
 * 	String	emitter\
 * )
 * @brief	set callback handling
 *
 * @param[in] emitter			Specify emitter name
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::Off(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	if(info.Length() < 1){
		Napi::TypeError::New(env, "No handle emitter name is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// check emitter name
	std::string	emitter  = info[0].ToString().Utf8Value();
	const char*	pemitter = GetNormalizationEmitter(emitter.c_str());
	if (nullptr == pemitter) {
		std::string msg	= "Unknown ";
		msg				+= emitter;
		msg				+= " emitter";
		Napi::TypeError::New(env, msg).ThrowAsJavaScriptException();
		return env.Undefined();
	}
	// unset callback
	return UnsetChmpxNodeCallback(info, pemitter);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffInitializeOnServer(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffInitializeOnServer(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffInitializeOnSlave(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffInitializeOnSlave(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffOpen(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffOpen(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_OPEN]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffClose(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffClose(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_CLOSE]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffSend(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffSend(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_SEND]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffBroadcast(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffBroadcast(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_BROADCAST]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffReply(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffReply(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_REPLY]);
}

/**
 * @memberof ChmpxNode
 * @fn void\
 * OffReceive(\
 * )
 * @brief	set callback handling for initializing chmpx object
 *
 * @return return true for success, false for failure
 */

Napi::Value ChmpxNode::OffReceive(const Napi::CallbackInfo& info)
{
	return UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_RECEIVE]);
}

/**
 * @memberof ChmpxNode
 * @fn bool\
 * InitializeOnServer(\
 * 	String	filepath\
 * 	, bool	is_auto_rejoin=false\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Initialize ChmpxNode object for on chmpx server node
 *
 *	Specify the configuration file which is loaded by chmpx server process.
 *	You can specify how to do when chmpx exited, waiting and rejoin or exiting.
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] filepath			Specify the configuration file path
 * @param[in] is_auto_rejoin	true means waiting to rejoin when chmpx process is down.
 *								false is error.
 * @param[in] cbfunc			callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns success(true) or failure(false).
 *
 */

Napi::Value ChmpxNode::InitializeOnServer(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No configuration file name is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : Required
	if(info[0].IsNull() || info[0].IsUndefined()){
		Napi::TypeError::New(env, "file name is empty.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	std::string	filename	= info[0].ToString().Utf8Value();

	// info[1]
	bool	is_auto_rejoin	= false;
	if(1 < info.Length()){
		if(info[1].IsFunction()){
			if(2 < info.Length()){
				Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
			maybeCallback	= info[1].As<Napi::Function>();
			hasCallback		= true;
		}else{
			is_auto_rejoin	= info[1].ToBoolean();
		}
	}

	// info[2]
	if(2 < info.Length()){
		if(3 < info.Length() || !info[2].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[2].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		InitializeOnWorker* worker = new InitializeOnWorker(maybeCallback, &(obj->_chmcntrl), filename, is_auto_rejoin, true);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		obj->_chmcntrl.Clean();
		bool result = obj->_chmcntrl.InitializeOnServer(filename.c_str(), is_auto_rejoin);
		return Napi::Boolean::New(env, result);
	}
}

/**
 * @memberof ChmpxNode
 * @fn bool\
 * InitializeOnSlave(\
 * 	String	filepath\
 * 	, bool	is_auto_rejoin=false\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Initialize ChmpxNode object for on chmpx slave node
 *
 *	Specify the configuration file which is loaded by chmpx server process.
 *	You can specify how to do when chmpx exited, waiting and rejoin or exiting.
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] filepath			Specify the configuration file path
 * @param[in] is_auto_rejoin	true means waiting to rejoin when chmpx process is down.
 *								false is error.
 * @param[in] cbfunc			callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns success(true) or failure(false).
 *
 */

Napi::Value ChmpxNode::InitializeOnSlave(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No configuration file name is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : Required
	if(info[0].IsNull() || info[0].IsUndefined()){
		Napi::TypeError::New(env, "file name is empty.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	std::string	filename	= info[0].ToString().Utf8Value();

	// info[1]
	bool	is_auto_rejoin	= false;
	if(1 < info.Length()){
		if(info[1].IsFunction()){
			if(2 < info.Length()){
				Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
			maybeCallback	= info[1].As<Napi::Function>();
			hasCallback		= true;
		}else{
			is_auto_rejoin	= info[1].ToBoolean();
		}
	}

	// info[2]
	if(2 < info.Length()){
		if(3 < info.Length() || !info[2].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[2].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		InitializeOnWorker* worker = new InitializeOnWorker(maybeCallback, &(obj->_chmcntrl), filename, is_auto_rejoin, false);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		obj->_chmcntrl.Clean();
		bool result = obj->_chmcntrl.InitializeOnSlave(filename.c_str(), is_auto_rejoin);
		return Napi::Boolean::New(env, result);
	}
}

/**
 * @memberof ChmpxNode
 * @fn int\
 * Send(\
 * 	Buffer		msgid\
 * 	, Buffer	body\
 *	, bool		is_routing=true\
 * 	, Callback cbfunc=null\
 * )
 *
 * @brief	Send data from slave node side to server node side.
 *
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] msgid			Specify msgid which is returned by ChmpxNode::Open()
 * @param[in] body			Specify send data
 * @param[in] is_routing	Specify true for sending data with routing automatically
 *							when chmpx type is HASH and replication count is over 1.
 *							Then the data sends multiple chmpx server node.
 * @param[in] cbfunc		callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns receiver count or -1 when something error occurred.
 *
 */

Napi::Value ChmpxNode::Send(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}else if(info.Length() < 2){
		Napi::TypeError::New(env, "No send data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_SEND]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : msgid Required
	if(!info[0].IsBuffer()){
		Napi::TypeError::New(env, "Wrong msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<uint8_t>	msgidbuf	= info[0].As<Napi::Buffer<uint8_t>>();
	size_t					msgidLen	= std::min(msgidbuf.Length(), static_cast<size_t>(sizeof(msgid_t)));
	msgid_t					msgid		= CHM_INVALID_MSGID;
	memcpy(&msgid, msgidbuf.Data(), msgidLen);

	// info[1] : data Required
	if(!info[1].IsBuffer()){
		Napi::TypeError::New(env, "Wrong send data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<unsigned char>	databuf	= info[1].As<Napi::Buffer<unsigned char>>();
	size_t						dataLen	= databuf.Length();
	ssize_t						binLen	= static_cast<ssize_t>(dataLen);		// adjust to size_t
	unsigned char*				pbinptr	= databuf.Data();
	ChmBinData					bindata;
	if(!pbinptr && 0 < dataLen){
		Napi::TypeError::New(env, "Could not access buffer data.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	bindata.Set(pbinptr, binLen);

	// info[2]
	bool	is_routing	= true;
	if(2 < info.Length()){
		if(info[2].IsFunction()){
			if(3 < info.Length()){
				Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
			maybeCallback	= info[2].As<Napi::Function>();
			hasCallback		= true;
		}else{
			is_routing	= info[2].ToBoolean();
		}
	}

	// info[3]
	if(3 < info.Length()){
		if(4 < info.Length() || !info[3].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[3].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		SendWorker* worker = new SendWorker(maybeCallback, &(obj->_chmcntrl), msgid, pbinptr, binLen, bindata.GetHash(), is_routing);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		long	recievercnt	= 0;
		if(!obj->_chmcntrl.Send(msgid, pbinptr, binLen, bindata.GetHash(), &recievercnt, is_routing)){
			recievercnt = -1;
		}
		return Napi::Number::New(env, static_cast<int32_t>(recievercnt));
	}
}

/**
 * @memberof ChmpxNode
 * @fn int\
 * Broadcast(\
 * 	Buffer		msgid\
 * 	, Buffer	body\
 * 	, Callback	cbfunc=null\
 * )
 * @brief	Broadcast data from slave node side to all server node side.
 *
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] msgid			Specify msgid which is returned by ChmpxNode::Open()
 * @param[in] body			Specify send data
 * @param[in] cbfunc		callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns receiver count or -1 when something error occurred.
 *
 */

Napi::Value ChmpxNode::Broadcast(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}else if(info.Length() < 2){
		Napi::TypeError::New(env, "No send data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_BROADCAST]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : msgid Required
	if(!info[0].IsBuffer()){
		Napi::TypeError::New(env, "Wrong msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<uint8_t>	msgidbuf	= info[0].As<Napi::Buffer<uint8_t>>();
	size_t					msgidLen	= std::min(msgidbuf.Length(), static_cast<size_t>(sizeof(msgid_t)));
	msgid_t					msgid		= CHM_INVALID_MSGID;
	memcpy(&msgid, msgidbuf.Data(), msgidLen);

	// info[1] : data Required
	if(!info[1].IsBuffer()){
		Napi::TypeError::New(env, "Wrong send data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<unsigned char>	databuf	= info[1].As<Napi::Buffer<unsigned char>>();
	size_t						dataLen	= databuf.Length();
	ssize_t						binLen	= static_cast<ssize_t>(dataLen);		// adjust to size_t
	unsigned char*				pbinptr	= databuf.Data();
	ChmBinData					bindata;
	if(!pbinptr && 0 < dataLen){
		Napi::TypeError::New(env, "Could not access buffer data.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	bindata.Set(pbinptr, binLen);

	// info[2]
	if(2 < info.Length()){
		if(3 < info.Length() || !info[2].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[2].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		BroadcastWorker* worker = new BroadcastWorker(maybeCallback, &(obj->_chmcntrl), msgid, pbinptr, binLen, bindata.GetHash());
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		long	recievercnt	= 0;
		if(!obj->_chmcntrl.Broadcast(msgid, pbinptr, binLen, bindata.GetHash(), &recievercnt)){
			recievercnt = -1;
		}
		return Napi::Number::New(env, static_cast<int32_t>(recievercnt));
	}
}

/**
 * @memberof ChmpxNode
 * @fn bool\
 * Reply(\
 * 	Buffer		ComPkt\
 * 	, Buffer	body\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Reply data from server node side to slave node side.
 *
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] ComPkt		Specify ComPkt which is received at ChmpxNode::Receive()
 * @param[in] body			Specify reply data
 * @param[in] cbfunc		callback function.
 *
 * @return	Return true for success, false for failure
 */

Napi::Value ChmpxNode::Reply(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No compkt is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}else if(info.Length() < 2){
		Napi::TypeError::New(env, "No reply data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_REPLY]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : compkt Required
	if(!info[0].IsBuffer()){
		Napi::TypeError::New(env, "Wrong compkt is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<unsigned char>	pktBuf	= info[0].As<Napi::Buffer<unsigned char>>();
	size_t						pktLen	= pktBuf.Length();
	const unsigned char*		pktptr	= pktBuf.Data();
	size_t						pktSize	= sizeof(COMPKT);
	size_t						copyLen	= std::min(pktLen, pktSize);
	COMPKT						compkt;

	if(!pktptr && 0 < pktLen){
		Napi::TypeError::New(env, "Could not access compkt.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	memset(&compkt, 0, pktSize);
	if(0 < copyLen){
		memcpy(reinterpret_cast<char*>(&compkt), pktptr, copyLen);
	}

	// info[1] : data Required
	if(!info[1].IsBuffer()){
		Napi::TypeError::New(env, "Wrong send data is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<unsigned char>	databuf	= info[1].As<Napi::Buffer<unsigned char>>();
	size_t						dataLen	= databuf.Length();
	ssize_t						binLen	= static_cast<ssize_t>(dataLen);		// adjust to size_t
	unsigned char*				pbinptr	= databuf.Data();
	ChmBinData					bindata;
	if(!pbinptr && 0 < dataLen){
		Napi::TypeError::New(env, "Could not access buffer data.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	bindata.Set(pbinptr, binLen);

	// info[2]
	if(2 < info.Length()){
		if(3 < info.Length() || !info[2].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[2].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		ReplyWorker* worker = new ReplyWorker(maybeCallback, &(obj->_chmcntrl), &compkt, pbinptr, binLen);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		bool result = obj->_chmcntrl.Reply(&compkt, pbinptr, binLen);
		return Napi::Boolean::New(env, result);
	}
}

/**
 * This Receive method allows two type arguments.
 * One of type is for joining on server, the other type is for joining on slave.
 * Each type has two pattern for without callback and with callback
 *
 *****************************************************************
 * On server node
 *****************************************************************
 * @memberof ChmpxNode
 * @fn bool\
 * Receive(\
 * 	Array outarr\
 * 	, int timeout_ms=0\
 * 	, bool no_giveup_rejoin=false\
 * )
 * @brief	Receive data on server node
 *
 *	Received data is set outarr which is Array.
 *	@li outarr[0]
 *		Type is Buffer, this value is ComPkt structure.
 *	@li outarr[1]
 *		Type is Buffer, this is set the received data.
 *
 * @param[out] outarr			Specify Array data type buffer for received data.
 *								outarr[0] is set ComPkt, and outarr[1] is set data.
 * @param[in] timeout_ms		Specify timeout ms for receiving.
 * @param[in] no_giveup_rejoin	Specify true for that upper limit for rejoin chmpx when
 *								chmpx is down is ignored.
 *
 * @return	Returns true for success, false for failure.
 *
 * @memberof ChmpxNode
 * @fn bool\
 * Receive(\
 * 	int timeout_ms=0\
 * 	, bool no_giveup_rejoin=false\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Receive data on server node with callback
 *
 *  This method works asynchronization and calls callback function at finishing.
 *
 * @param[in] timeout_ms		Specify timeout ms for receiving.
 * @param[in] no_giveup_rejoin	Specify true for that upper limit for rejoin chmpx when
 *								chmpx is down is ignored.
 * @param[in] cbfunc			callback function.
 *
 * @return	Returns true for success, false for failure.
 *
 *****************************************************************
 * On slave node
 *****************************************************************
 * @memberof ChmpxNode
 * @fn bool\
 * Receive(\
 * 	Buffer	msgid\
 * 	, Array	outarr\
 * 	, int	timeout_ms=0\
 * )
 * @brief	Receive data on slave node
 *
 *	Received data is set outarr which is Array.
 *	@li outarr[0]
 *		Type is Buffer, this value is ComPkt structure.
 *	@li outarr[1]
 *		Type is Buffer, this is set the received data.
 *
 * @param[in] msgid				Specify msgid which is received from ChmpxNode::Open()
 * @param[out] outarr			Specify Array data type buffer for received data.
 *								outarr[0] is set ComPkt, and outarr[1] is set data.
 * @param[in] timeout_ms		Specify timeout ms for receiving.
 *
 * @return	Returns true for success, false for failure.
 *
 * @memberof ChmpxNode
 * @fn bool\
 * Receive(\
 * 	Buffer	msgid\
 * 	, int	timeout_ms=0\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Receive data on slave node
 *
 *  This method works asynchronization and calls callback function at finishing.
 *
 * @param[in] msgid				Specify msgid which is received from ChmpxNode::Open()
 * @param[in] timeout_ms		Specify timeout ms for receiving.
 * @param[in] cbfunc			callback function.
 *
 * @return	Returns true for success, false for failure.
 *
 */

Napi::Value ChmpxNode::Receive(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj = Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// [NOTE]
	// Here the Emitter is detected, but it is not yet determined whether
	// to invoke the Callback.
	//
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_RECEIVE]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// common variables
	bool			is_on_server	= obj->_chmcntrl.IsClientOnSvrType();
	Napi::Array		rcvarr;
	msgid_t			msgid			= CHM_INVALID_MSGID;			// only on slave type
	int				timeout_ms		= 0;
	bool			no_giveup_rejoin= false;						// only on server type

	//
	// parse parameter and check method type
	//
	if(is_on_server){
		//---------------------------------------------
		// on server type
		//---------------------------------------------
		bool	precheck_callback = false;
		if(info.Length() < 1){
			precheck_callback = true;
		}else{
			if(!info[0].IsArray()){
				precheck_callback = true;
			}
		}

		if(!precheck_callback){
			// Synchronous (no callback)
			hasCallback = false;

			// info[0] = receive data array
			rcvarr = info[0].As<Napi::Array>();

			// info[1]
			if(1 < info.Length()){
				if(!info[1].IsBoolean()){
					// info[1] = timeout ms
					timeout_ms = info[1].ToNumber().Int32Value();

					if(2 < info.Length()){
						// info[2] = no giveup flag
						if(3 < info.Length()){
							Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						if(!info[2].IsBoolean()){
							Napi::TypeError::New(env, "Unknown parameter is specified for loop flag.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						no_giveup_rejoin = info[2].ToBoolean();
					}
				}else{
					// info[1] = no giveup flag
					if(2 < info.Length()){
						Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
						return env.Undefined();
					}
					no_giveup_rejoin = info[1].ToBoolean();
				}
			}

		}else{
			// Asynchronous (allow callback)
			if(0 < info.Length()){
				if(info[0].IsBoolean()){
					// info[0] = no giveup flag
					no_giveup_rejoin = info[0].ToBoolean();

					if(1 < info.Length()){
						// info[1] = callback function
						if(2 < info.Length()){
							Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						if(!info[1].IsFunction()){
							Napi::TypeError::New(env, "Unknown parameter is specified for callback function.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						maybeCallback	= info[1].As<Napi::Function>();
						hasCallback		= true;
					}

				}else if(info[0].IsFunction()){
					// info[0] = callback function
					if(1 < info.Length()){
						Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
						return env.Undefined();
					}
					maybeCallback	= info[0].As<Napi::Function>();
					hasCallback		= true;

				}else{
					// info[0] = timeout ms
					timeout_ms = info[0].ToNumber().Int32Value();

					if(1 < info.Length()){
						if(info[1].IsBoolean()){
							// info[1] = no giveup flag
							no_giveup_rejoin = info[1].ToBoolean();

							if(2 < info.Length()){
								// info[2] = callback function
								if(3 < info.Length()){
									Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
									return env.Undefined();
								}
								if(!info[2].IsFunction()){
									Napi::TypeError::New(env, "Unknown parameter is specified for callback function.").ThrowAsJavaScriptException();
									return env.Undefined();
								}
								maybeCallback	= info[2].As<Napi::Function>();
								hasCallback		= true;
							}

						}else if(info[1].IsFunction()){
							// info[1] = callback function
							if(2 < info.Length()){
								Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
								return env.Undefined();
							}
							maybeCallback	= info[1].As<Napi::Function>();
							hasCallback		= true;
						}else{
							Napi::TypeError::New(env, "Unknown parameter is specified for no giveup flag or callback function.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
					}
				}
			}
			if(!hasCallback){
				Napi::TypeError::New(env, "Called receive method without callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
		}

	}else{
		//---------------------------------------------
		// on slave type
		//---------------------------------------------
		// info[0] : msgid Required
		if(info.Length() < 1 || !info[0].IsBuffer()){
			Napi::TypeError::New(env, "Wrong msgid is specified.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		Napi::Buffer<uint8_t>	msgidbuf = info[0].As<Napi::Buffer<uint8_t>>();
		size_t					msgidLen = std::min(msgidbuf.Length(), static_cast<size_t>(sizeof(msgid_t)));
		memcpy(&msgid, msgidbuf.Data(), msgidLen);

		// precheck parameter whichever callback
		bool	precheck_callback = false;
		if(info.Length() < 2){
			precheck_callback = true;
		}else{
			if(!info[1].IsArray()){
				precheck_callback = true;
			}
		}

		if(!precheck_callback){
			// Synchronous (no callback)
			hasCallback = false;

			// info[1] = receive data array
			rcvarr = info[1].As<Napi::Array>();

			if(2 < info.Length()){
				// info[2] = timeout ms
				if(3 < info.Length()){
					Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
					return env.Undefined();
				}
				timeout_ms = info[2].ToNumber().Int32Value();
			}

		}else{
			// Asynchronous (allow callback)
			if(1 < info.Length()){
				if(!info[1].IsFunction()){
					// info[1] = timeout ms
					timeout_ms = info[1].ToNumber().Int32Value();

					if(2 < info.Length()){
						// info[2] = callback function
						if(3 < info.Length()){
							Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						if(!info[2].IsFunction()){
							Napi::TypeError::New(env, "Unknown parameter is specified for callback function.").ThrowAsJavaScriptException();
							return env.Undefined();
						}
						maybeCallback	= info[2].As<Napi::Function>();
						hasCallback		= true;
					}
				}else{
					// info[1] = callback function
					if(2 < info.Length()){
						Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
						return env.Undefined();
					}
					maybeCallback	= info[1].As<Napi::Function>();
					hasCallback		= true;
				}
			}
			if(!hasCallback){
				Napi::TypeError::New(env, "Called receive method without callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
		}
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		if(is_on_server){
			ReceiveWorker* worker = new ReceiveWorker(maybeCallback, &(obj->_chmcntrl), timeout_ms, no_giveup_rejoin);
			worker->Queue();
		}else{
			ReceiveWorker* worker = new ReceiveWorker(maybeCallback, &(obj->_chmcntrl), msgid, timeout_ms);
			worker->Queue();
		}
		return Napi::Boolean::New(env, true);
	}else{
		PCOMPKT			pComPkt	= nullptr;
		unsigned char*	pBody	= nullptr;
		size_t			Length	= 0;
		bool			result;

		// receive
		if(is_on_server){
			result = obj->_chmcntrl.Receive(&pComPkt, &pBody, &Length, timeout_ms, no_giveup_rejoin);
		}else{
			result = obj->_chmcntrl.Receive(msgid, &pComPkt, &pBody, &Length, timeout_ms);
		}
		// set result data to array
		if(!pComPkt && result){
			result = false;			// maybe timeouted
		}
		if(result){
			// set COMPKT to array[0]
			Napi::Value	pktBuf = Napi::Buffer<char>::Copy(env, reinterpret_cast<char*>(pComPkt), static_cast<size_t>(sizeof(COMPKT)));
			rcvarr.Set(static_cast<uint32_t>(0), pktBuf);

			// set body to array[1]
			Napi::Value bodyBuf;
			if(pBody && 0 < Length){
				bodyBuf = Napi::Buffer<unsigned char>::Copy(env, reinterpret_cast<unsigned char*>(pBody), static_cast<size_t>(Length));
			}else{
				bodyBuf = Napi::Buffer<unsigned char>::New(env, 0);
			}
			rcvarr.Set(static_cast<uint32_t>(1), bodyBuf);
		}
		CHM_Free(pComPkt);
		CHM_Free(pBody);

		return Napi::Boolean::New(env, result);
	}
}

/**
 * @memberof ChmpxNode
 * @fn Buffer\
 * Open(\
 * 	bool no_giveup_rejoin=false\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Open the message handle(msgid) on slave node.
 *
 *	You can specify the flag whichever it waits for up coming chmpx process
 *	after chmpx process is down.
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] no_giveup_rejoin	Specify true for that upper limit for rejoin chmpx when
 *								chmpx is down is ignored.
 * @param[in] cbfunc			callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns msgid which is opened but if something error occurred, returns null.
 */

Napi::Value ChmpxNode::Open(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_OPEN]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0]
	bool	no_giveup_rejoin = false;
	if(0 < info.Length()){
		if(info[0].IsFunction()){
			if(1 < info.Length()){
				Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
				return env.Undefined();
			}
			maybeCallback	= info[0].As<Napi::Function>();
			hasCallback		= true;
		}else{
			no_giveup_rejoin= info[0].ToBoolean();
		}
	}

	// info[1]
	if(1 < info.Length()){
		if(2 < info.Length()){
			Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		if(!info[1].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[0].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		OpenWorker* worker = new OpenWorker(maybeCallback, &(obj->_chmcntrl), no_giveup_rejoin);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		msgid_t	msgid = obj->_chmcntrl.Open(no_giveup_rejoin);
		if(CHM_INVALID_MSGID == msgid){
			return env.Null();
		}
	    return Napi::Buffer<uint8_t>::Copy(env, reinterpret_cast<uint8_t*>(&msgid), static_cast<size_t>(sizeof(msgid_t)));
	}
}

/**
 * @memberof ChmpxNode
 * @fn bool\
 * Close(\
 * 	Buffer msgid\
 * 	, Callback cbfunc=null\
 * )
 * @brief	Close the message handle(msgid).
 *
 *	If the callback function is specified, or on callback handles for this,
 *  this method works asynchronization and calls callback function at finishing.
 *
 * @param[in] msgid		Specify msgid which is returned ChmpxNode::Open()
 * @param[in] cbfunc			callback function.
 *
 * @return	If a callback is set, always return true.
 *			Otherwise, returns success(true) or failure(false).
 *
 */

Napi::Value ChmpxNode::Close(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// check
	if(info.Length() < 1){
		Napi::TypeError::New(env, "No msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	// initial callback comes from emitter map if set
	Napi::Function				maybeCallback;
	bool						hasCallback		= false;
	Napi::FunctionReference*	emitterCbRef	= obj->_cbs.Find(stc_emitters[EMITTER_POS_CLOSE]);
	if(emitterCbRef){
		maybeCallback	= emitterCbRef->Value();
		hasCallback		= true;
	}

	// info[0] : msgid Required
	if(!info[0].IsBuffer()){
		Napi::TypeError::New(env, "Wrong msgid is specified.").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	Napi::Buffer<uint8_t>	msgidbuf	= info[0].As<Napi::Buffer<uint8_t>>();
	size_t					msgidLen	= std::min(msgidbuf.Length(), static_cast<size_t>(sizeof(msgid_t)));
	msgid_t					msgid		= CHM_INVALID_MSGID;
	memcpy(&msgid, msgidbuf.Data(), msgidLen);

	// info[1]
	if(1 < info.Length()){
		if(2 < info.Length()){
			Napi::TypeError::New(env, "Too many parameters.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		if(!info[1].IsFunction()){
			Napi::TypeError::New(env, "Last parameter is not callback function.").ThrowAsJavaScriptException();
			return env.Undefined();
		}
		maybeCallback	= info[1].As<Napi::Function>();
		hasCallback		= true;
	}

	// Execute
	if(hasCallback){
		// Create worker and Queue it
		CloseWorker* worker = new CloseWorker(maybeCallback, &(obj->_chmcntrl), msgid);
		worker->Queue();
		return Napi::Boolean::New(env, true);
	}else{
		bool result = obj->_chmcntrl.Close(msgid);
		return Napi::Boolean::New(env, result);
	}
}

/**
 * @memberof ChmpxNode
 * @fn bool isChmpxExit()
 * @brief	Check the chmpx process's status(running or exit)
 *
 * @return	Returns true as chmpx process is running, false means chmpx process does not exist.
 */

Napi::Value ChmpxNode::IsChmpxExit(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();

	// Unwrap
	if(!info.This().IsObject() || !info.This().As<Napi::Object>().InstanceOf(ChmpxNode::constructor.Value())){
		Napi::TypeError::New(env, "Invalid this object(ChmpxNode instance)").ThrowAsJavaScriptException();
		return env.Undefined();
	}
	ChmpxNode*	obj	= Napi::ObjectWrap<ChmpxNode>::Unwrap(info.This().As<Napi::Object>());

	bool result = obj->_chmcntrl.IsChmpxExit();
	return Napi::Boolean::New(env, result);
}

//@}

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
