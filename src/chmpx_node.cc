/*
 * CHMPX
 *
 * Copyright 2015 Yahoo! JAPAN corporation.
 *
 * CHMPX is inprocess data exchange by MQ with consistent hashing.
 * CHMPX is made for the purpose of the construction of
 * original messaging system and the offer of the client
 * library.
 * CHMPX transfers messages between the client and the server/
 * slave. CHMPX based servers are dispersed by consistent
 * hashing and are automatically layouted. As a result, it
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

using namespace v8;
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
		return NULL;
	}
	for(const char** ptmp = &stc_emitters[0]; ptmp && *ptmp; ++ptmp){
		if(0 == strcasecmp(*ptmp, emitter)){
			return *ptmp;
		}
	}
	return NULL;
}

//---------------------------------------------------------
// Utility macros
//---------------------------------------------------------
#define	SetChmpxNodeCallback(info, pos, pemitter) \
		{ \
			ChmpxNode*	obj = Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This()); \
			if(info.Length() <= pos){ \
				Nan::ThrowSyntaxError("No callback is specified."); \
				return; \
			} \
			Nan::Callback* cb = new Nan::Callback(); \
			cb->SetFunction(info[pos].As<v8::Function>()); \
			bool	result = obj->_cbs.Set(pemitter, cb); \
			info.GetReturnValue().Set(Nan::New(result)); \
		}

#define	UnsetChmpxNodeCallback(info, pemitter) \
		{ \
			ChmpxNode*	obj		= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This()); \
			bool		result	= obj->_cbs.Unset(pemitter); \
			info.GetReturnValue().Set(Nan::New(result)); \
		}

//---------------------------------------------------------
// ChmpxNode Class
//---------------------------------------------------------
Nan::Persistent<Function>	ChmpxNode::constructor;

//---------------------------------------------------------
// ChmpxNode Methods
//---------------------------------------------------------
ChmpxNode::ChmpxNode() : _chmcntrl(), _cbs()
{
}

ChmpxNode::~ChmpxNode()
{
	_chmcntrl.Clean();
}

void ChmpxNode::Init()
{
	// Prepare constructor template
	Local<FunctionTemplate>	tpl = Nan::New<FunctionTemplate>(New); 
	tpl->SetClassName(Nan::New("ChmpxNode").ToLocalChecked()); 
	tpl->InstanceTemplate()->SetInternalFieldCount(1); 

	Nan::SetPrototypeMethod(tpl, "on",						On);
	Nan::SetPrototypeMethod(tpl, "onInitializeOnServer",	OnInitializeOnServer);
	Nan::SetPrototypeMethod(tpl, "onInitializeOnSlave",		OnInitializeOnSlave);
	Nan::SetPrototypeMethod(tpl, "onOpen",					OnOpen);
	Nan::SetPrototypeMethod(tpl, "onClose",					OnClose);
	Nan::SetPrototypeMethod(tpl, "onSend",					OnSend);
	Nan::SetPrototypeMethod(tpl, "onBroadcast",				OnBroadcast);
	Nan::SetPrototypeMethod(tpl, "onReply",					OnReply);
	Nan::SetPrototypeMethod(tpl, "onReceive",				OnReceive);
	Nan::SetPrototypeMethod(tpl, "off",						Off);
	Nan::SetPrototypeMethod(tpl, "offInitializeOnServer",	OffInitializeOnServer);
	Nan::SetPrototypeMethod(tpl, "offInitializeOnSlave",	OffInitializeOnSlave);
	Nan::SetPrototypeMethod(tpl, "offOpen",					OffOpen);
	Nan::SetPrototypeMethod(tpl, "offClose",				OffClose);
	Nan::SetPrototypeMethod(tpl, "offSend",					OffSend);
	Nan::SetPrototypeMethod(tpl, "offBroadcast",			OffBroadcast);
	Nan::SetPrototypeMethod(tpl, "offReply",				OffReply);
	Nan::SetPrototypeMethod(tpl, "offReceive",				OffReceive);

	Nan::SetPrototypeMethod(tpl, "initializeOnServer",		InitializeOnServer);
	Nan::SetPrototypeMethod(tpl, "initializeOnSlave",		InitializeOnSlave);
	Nan::SetPrototypeMethod(tpl, "send",					Send);
	Nan::SetPrototypeMethod(tpl, "broadcast",				Broadcast);
	Nan::SetPrototypeMethod(tpl, "receive",					Receive);
	Nan::SetPrototypeMethod(tpl, "reply",					Reply);
	Nan::SetPrototypeMethod(tpl, "open",					Open);
	Nan::SetPrototypeMethod(tpl, "close",					Close);
	Nan::SetPrototypeMethod(tpl, "isChmpxExit",				IsChmpxExit);

	// Regist
	constructor.Reset(tpl->GetFunction()); 
}

NAN_METHOD(ChmpxNode::New)
{
	if(info.IsConstructCall()){ 
		// Invoked as constructor: new ChmpxNode()
		ChmpxNode*	obj = new ChmpxNode();
		obj->Wrap(info.This()); 
		info.GetReturnValue().Set(info.This());
	}else{ 
		// Invoked as plain function ChmpxNode(), turn into construct call.
		const unsigned	argc		= 1;
		Local<Value>	argv[argc]	= {info[0]};
		Local<Function>	cons		= Nan::New<Function>(constructor);
		info.GetReturnValue().Set(Nan::NewInstance(cons, argc, argv).ToLocalChecked());
	}
}

NAN_METHOD(ChmpxNode::NewInstance)
{
	const unsigned	argc		= 1;
	Local<Value>	argv[argc]	= {info[0]}; 
	Local<Function>	cons		= Nan::New<Function>(constructor); 
	info.GetReturnValue().Set(Nan::NewInstance(cons, argc, argv).ToLocalChecked()); 
}

Local<Object> ChmpxNode::GetInstance(Nan::NAN_METHOD_ARGS_TYPE info)
{
	Nan::EscapableHandleScope	scope;

	const unsigned	argc		= 1;
	Local<Value>	argv[argc]	= {info[0]}; 
	Local<Function>	cons		= Nan::New<Function>(constructor); 
	Local<Object> 	instance	= Nan::NewInstance(cons, argc, argv).ToLocalChecked();

	return scope.Escape(instance);
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

NAN_METHOD(ChmpxNode::On)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No handle emitter name is specified.");
		return;
	}else if(info.Length() < 2){
		Nan::ThrowSyntaxError("No callback is specified.");
		return;
	}

	// check emitter name
	Nan::Utf8String	emitter(info[0]);
	const char*		pemitter;
	if(NULL == (pemitter = GetNormalizationEmitter(*emitter))){
		string	msg = "Unknown ";
		msg			+= *emitter;
		msg			+= " emitter";
		Nan::ThrowSyntaxError(msg.c_str());
		return;
	}
	// add callback
	SetChmpxNodeCallback(info, 1, pemitter);
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

NAN_METHOD(ChmpxNode::OnInitializeOnServer)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
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

NAN_METHOD(ChmpxNode::OnInitializeOnSlave)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
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

NAN_METHOD(ChmpxNode::OnOpen)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_OPEN]);
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

NAN_METHOD(ChmpxNode::OnClose)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_CLOSE]);
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

NAN_METHOD(ChmpxNode::OnSend)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_SEND]);
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

NAN_METHOD(ChmpxNode::OnBroadcast)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_BROADCAST]);
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

NAN_METHOD(ChmpxNode::OnReply)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_REPLY]);
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

NAN_METHOD(ChmpxNode::OnReceive)
{
	SetChmpxNodeCallback(info, 0, stc_emitters[EMITTER_POS_RECEIVE]);
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

NAN_METHOD(ChmpxNode::Off)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No handle emitter name is specified.");
		return;
	}

	// check emitter name
	Nan::Utf8String	emitter(info[0]);
	const char*		pemitter;
	if(NULL == (pemitter = GetNormalizationEmitter(*emitter))){
		string	msg = "Unknown ";
		msg			+= *emitter;
		msg			+= " emitter";
		Nan::ThrowSyntaxError(msg.c_str());
		return;
	}
	// unset callback
	UnsetChmpxNodeCallback(info, pemitter);
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

NAN_METHOD(ChmpxNode::OffInitializeOnServer)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
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

NAN_METHOD(ChmpxNode::OffInitializeOnSlave)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
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

NAN_METHOD(ChmpxNode::OffOpen)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_OPEN]);
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

NAN_METHOD(ChmpxNode::OffClose)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_CLOSE]);
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

NAN_METHOD(ChmpxNode::OffSend)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_SEND]);
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

NAN_METHOD(ChmpxNode::OffBroadcast)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_BROADCAST]);
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

NAN_METHOD(ChmpxNode::OffReply)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_REPLY]);
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

NAN_METHOD(ChmpxNode::OffReceive)
{
	UnsetChmpxNodeCallback(info, stc_emitters[EMITTER_POS_RECEIVE]);
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

NAN_METHOD(ChmpxNode::InitializeOnServer)
{
	ChmpxNode*	obj = Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	// check parameters and set
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No configuration file name is specified.");
		return;
	}
	Nan::Utf8String	filename(info[0]);
	bool			is_auto_rejoin	= false;
	Nan::Callback*	callback		= obj->_cbs.Find(stc_emitters[EMITTER_POS_INITIALIZEONSERVER]);
	if(2 == info.Length()){
		if(info[1]->IsFunction()){
			// function
			callback		= new Nan::Callback(info[1].As<v8::Function>());
		}else{
			is_auto_rejoin	= info[1]->BooleanValue();
		}
	}else if(2 < info.Length()){
		if(!info[2]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		is_auto_rejoin	= info[1]->BooleanValue();
		callback		= new Nan::Callback(info[2].As<v8::Function>());
	}

	// work
	if(callback){
		Nan::AsyncQueueWorker(new InitializeOnWorker(callback, &(obj->_chmcntrl), *filename, is_auto_rejoin, true));
		info.GetReturnValue().Set(Nan::True());
	}else{
		obj->_chmcntrl.Clean();
		info.GetReturnValue().Set(Nan::New(obj->_chmcntrl.InitializeOnServer(*filename, is_auto_rejoin)));
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

NAN_METHOD(ChmpxNode::InitializeOnSlave)
{
	ChmpxNode*	obj = Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	// check parameters and set
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No configuration file name is specified.");
		return;
	}
	Nan::Utf8String	filename(info[0]);
	bool			is_auto_rejoin	= false;
	Nan::Callback*	callback		= obj->_cbs.Find(stc_emitters[EMITTER_POS_INITIALIZEONSLAVE]);
	if(2 == info.Length()){
		if(info[1]->IsFunction()){
			// function
			callback		= new Nan::Callback(info[1].As<v8::Function>());
		}else{
			is_auto_rejoin	= info[1]->BooleanValue();
		}
	}else if(2 < info.Length()){
		if(!info[2]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		is_auto_rejoin	= info[1]->BooleanValue();
		callback		= new Nan::Callback(info[2].As<v8::Function>());
	}

	// work
	if(callback){
		Nan::AsyncQueueWorker(new InitializeOnWorker(callback, &(obj->_chmcntrl), *filename, is_auto_rejoin, false));
		info.GetReturnValue().Set(Nan::True());
	}else{
		obj->_chmcntrl.Clean();
		info.GetReturnValue().Set(Nan::New(obj->_chmcntrl.InitializeOnSlave(*filename, is_auto_rejoin)));
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

NAN_METHOD(ChmpxNode::Send)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No msgid is specified.");
		return;
	}else if(info.Length() < 2){
		Nan::ThrowSyntaxError("No send data is specified.");
		return;
	}

	ChmpxNode*		obj			= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	// msgid
	msgid_t			msgid;
	char*			ptmpmsgid	= reinterpret_cast<char*>(&msgid);
	Nan::DecodeWrite(ptmpmsgid, Nan::DecodeBytes(info[0], Nan::BINARY), info[0], Nan::BINARY);

	// data
	ssize_t			binsize		= Nan::DecodeBytes(info[1], Nan::BUFFER);
	unsigned char*	pbinptr		= reinterpret_cast<unsigned char*>(node::Buffer::Data(info[1]));
	ChmBinData		bindata;
	if(!pbinptr){
		Nan::ThrowSyntaxError("Could not allocate memory.");
		return;
	}
	bindata.Set(pbinptr, binsize);

	// other
	bool			is_routing	= true;
	Nan::Callback*	callback	= obj->_cbs.Find(stc_emitters[EMITTER_POS_SEND]);
	if(2 < info.Length()){
		if(info[2]->IsFunction()){
			callback = new Nan::Callback(info[2].As<v8::Function>());
		}else{
			is_routing = info[2]->BooleanValue();
			if(3 < info.Length()){
				if(!info[3]->IsFunction()){
					// must callback function is spacified at last pos.
					Nan::ThrowSyntaxError("Last parameter is not callback function.");
					return;
				}
				callback = new Nan::Callback(info[3].As<v8::Function>());
			}
		}
	}

	// work
	if(callback){
		Nan::AsyncQueueWorker(new SendWorker(callback, &(obj->_chmcntrl), msgid, pbinptr, binsize, bindata.GetHash(), is_routing));
		info.GetReturnValue().Set(Nan::True());
	}else{
		long	recievercnt	= 0;
		if(!obj->_chmcntrl.Send(msgid, pbinptr, binsize, bindata.GetHash(), &recievercnt, is_routing)){
			recievercnt = -1;
		}
		info.GetReturnValue().Set(Nan::New<Integer>(static_cast<int32_t>(recievercnt)));
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

NAN_METHOD(ChmpxNode::Broadcast)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No msgid is specified.");
		return;
	}else if(info.Length() < 2){
		Nan::ThrowSyntaxError("No send data is specified.");
		return;
	}

	ChmpxNode*		obj			= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	// msgid
	msgid_t			msgid;
	char*			ptmpmsgid	= reinterpret_cast<char*>(&msgid);
	Nan::DecodeWrite(ptmpmsgid, Nan::DecodeBytes(info[0], Nan::BINARY), info[0], Nan::BINARY);

	// data
	ssize_t			binsize		= Nan::DecodeBytes(info[1], Nan::BUFFER);
	unsigned char*	pbinptr		= reinterpret_cast<unsigned char*>(node::Buffer::Data(info[1]));
	ChmBinData		bindata;
	if(!pbinptr){
		Nan::ThrowSyntaxError("Could not allocate memory.");
		return;
	}
	bindata.Set(pbinptr, binsize);

	// callback
	Nan::Callback*	callback	= obj->_cbs.Find(stc_emitters[EMITTER_POS_BROADCAST]);
	if(2 < info.Length()){
		if(!info[2]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		callback = new Nan::Callback(info[2].As<v8::Function>());
	}

	// work
	if(callback){
		Nan::AsyncQueueWorker(new BroadcastWorker(callback, &(obj->_chmcntrl), msgid, pbinptr, binsize, bindata.GetHash()));
		info.GetReturnValue().Set(Nan::True());
	}else{
		long	recievercnt	= 0;
		if(!obj->_chmcntrl.Broadcast(msgid, pbinptr, binsize, bindata.GetHash(), &recievercnt)){
			recievercnt = -1;
		}
		info.GetReturnValue().Set(Nan::New<Integer>(static_cast<int32_t>(recievercnt)));
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

NAN_METHOD(ChmpxNode::Reply)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No compkt is specified.");
		return;
	}else if(info.Length() < 2){
		Nan::ThrowSyntaxError("No reply data is specified.");
		return;
	}

	ChmpxNode*		obj		= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	// compkt
	COMPKT			compkt;
	char*			ppktbuf	= reinterpret_cast<char*>(&compkt);
	Nan::DecodeWrite(ppktbuf, Nan::DecodeBytes(info[0], Nan::BINARY), info[0], Nan::BINARY);

	// data
	ssize_t			binsize	= Nan::DecodeBytes(info[1], Nan::BUFFER);
	unsigned char*	pbinptr	= reinterpret_cast<unsigned char*>(node::Buffer::Data(info[1]));
	if(!pbinptr){
		Nan::ThrowSyntaxError("Could not allocate memory.");
		return;
	}

	// callback
	Nan::Callback*	callback= obj->_cbs.Find(stc_emitters[EMITTER_POS_REPLY]);
	if(2 < info.Length()){
		if(!info[2]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		callback = new Nan::Callback(info[2].As<v8::Function>());
	}


	// work
	if(callback){
		Nan::AsyncQueueWorker(new ReplyWorker(callback, &(obj->_chmcntrl), &compkt, pbinptr, binsize));
		info.GetReturnValue().Set(Nan::True());
	}else{
		info.GetReturnValue().Set(Nan::New(obj->_chmcntrl.Reply(&compkt, pbinptr, binsize)));
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
 * @param[out] outarr			Specify Array data type buffer for recieved data.
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
 * @param[out] outarr			Specify Array data type buffer for recieved data.
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

NAN_METHOD(ChmpxNode::Receive)
{
	ChmpxNode*		obj				= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());
	bool			is_on_server	= obj->_chmcntrl.IsClientOnSvrType();
	Local<Array>	rcvarr;
	msgid_t			msgid			= CHM_INVALID_MSGID;			// only on slave type
	int				timeout_ms		= 0;
	bool			no_giveup_rejoin= false;						// only on server type
	Nan::Callback*	callback		= NULL;

	// parse parameter and check method type
	if(is_on_server){
		// on server type
		bool	precheck_callback = false;
		if(info.Length() < 1){
			precheck_callback = true;
		}else{
			if(!info[0]->IsArray()){
				precheck_callback = true;
			}
		}
		if(!precheck_callback){
			// without callback
			// argv[0] = receive data array
			rcvarr = Local<Array>::Cast(info[0]);
			if(1 < info.Length()){
				if(!info[1]->IsBoolean()){
					// argv[1] = timeout ms
					timeout_ms = info[1]->NumberValue();
					if(2 < info.Length()){
						// argv[2] = no giveup flag
						if(!info[2]->IsBoolean()){
							Nan::ThrowSyntaxError("Unknown parameter is specified for loop flag.");
							return;
						}
						no_giveup_rejoin = info[2]->BooleanValue();
					}
				}else{
					// argv[1] = no giveup flag
					no_giveup_rejoin = info[1]->BooleanValue();
				}
			}
		}else{
			// with callback
			callback = obj->_cbs.Find(stc_emitters[EMITTER_POS_RECEIVE]);

			if(0 < info.Length()){
				if(info[0]->IsBoolean()){
					// argv[0] = no giveup flag
					no_giveup_rejoin = info[0]->BooleanValue();
					if(1 < info.Length()){
						// argv[1] = callback function
						if(!info[1]->IsFunction()){
							Nan::ThrowSyntaxError("Unknown parameter is specified for callback function.");
							return;
						}
						callback = new Nan::Callback(info[1].As<v8::Function>());
					}
				}else if(info[0]->IsFunction()){
					// argv[0] = callback function
					callback = new Nan::Callback(info[0].As<v8::Function>());

				}else{
					// argv[0] = timeout ms
					timeout_ms = info[0]->NumberValue();
					if(1 < info.Length()){
						if(info[1]->IsBoolean()){
							// argv[1] = no giveup flag
							no_giveup_rejoin = info[1]->BooleanValue();
							if(2 < info.Length()){
								if(!info[2]->IsFunction()){
									Nan::ThrowSyntaxError("Unknown parameter is specified for callback function.");
									return;
								}
								// argv[2] = callback function
								callback = new Nan::Callback(info[2].As<v8::Function>());
							}
						}else if(info[1]->IsFunction()){
							// argv[1] = callback function
							callback = new Nan::Callback(info[1].As<v8::Function>());
						}else{
							Nan::ThrowSyntaxError("Unknown parameter is specified for no giveup flag or callback function.");
							return;
						}
					}
				}
			}
			if(!callback){
				Nan::ThrowSyntaxError("Called receive method without callback function.");
				return;
			}
		}
	}else{
		// on slave type
		// argv[0] = msgid
		if(info.Length() < 1){
			Nan::ThrowSyntaxError("No msgid is specified.");
			return;
		}
		char*	ptmpmsgid = reinterpret_cast<char*>(&msgid);
		Nan::DecodeWrite(ptmpmsgid, Nan::DecodeBytes(info[0], Nan::BINARY), info[0], Nan::BINARY);

		// precheck parameter whichever callback
		bool	precheck_callback = false;
		if(info.Length() < 2){
			precheck_callback = true;
		}else{
			if(!info[1]->IsArray()){
				precheck_callback = true;
			}
		}

		if(!precheck_callback){
			// without callback
			// argv[1] = receive data array
			rcvarr = Local<Array>::Cast(info[1]);

			if(2 < info.Length()){
				// argv[2] = timeout ms
				timeout_ms = info[2]->NumberValue();
			}
		}else{
			// with callback
			callback = obj->_cbs.Find(stc_emitters[EMITTER_POS_RECEIVE]);

			if(1 < info.Length()){
				if(!info[1]->IsFunction()){
					// argv[1] = timeout ms
					timeout_ms = info[1]->NumberValue();
					if(2 < info.Length()){
						// argv[2] = callback function
						if(!info[2]->IsFunction()){
							Nan::ThrowSyntaxError("Unknown parameter is specified for callback function.");
							return;

						}
						callback = new Nan::Callback(info[2].As<v8::Function>());
					}
				}else{
					// argv[1] = callback function
					callback = new Nan::Callback(info[1].As<v8::Function>());
				}
			}
			if(!callback){
				Nan::ThrowSyntaxError("Called receive method without callback function.");
				return;
			}
		}
	}

	// work
	if(callback){
		if(is_on_server){
			Nan::AsyncQueueWorker(new ReceiveWorker(callback, &(obj->_chmcntrl), timeout_ms, no_giveup_rejoin));
		}else{
			Nan::AsyncQueueWorker(new ReceiveWorker(callback, &(obj->_chmcntrl), msgid, timeout_ms));
		}
		info.GetReturnValue().Set(Nan::True());
	}else{
		PCOMPKT			pComPkt	= NULL;
		unsigned char*	pBody	= NULL;
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
			// set recieved data to array
			rcvarr->Set(0, Nan::Encode(pComPkt,	sizeof(COMPKT), Nan::BINARY));
			rcvarr->Set(1, Nan::Encode(pBody,	Length,			Nan::BUFFER));
		}
		CHM_Free(pComPkt);
		CHM_Free(pBody);

		info.GetReturnValue().Set(Nan::New(result));
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
 *	You can specify the flag whichever it waits for up comming chmpx process
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

NAN_METHOD(ChmpxNode::Open)
{
	ChmpxNode*		obj				= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());
	bool			no_giveup_rejoin= false;
	Nan::Callback*	callback		= obj->_cbs.Find(stc_emitters[EMITTER_POS_OPEN]);

	if(1 == info.Length()){
		if(info[0]->IsFunction()){
			callback		= new Nan::Callback(info[0].As<v8::Function>());
		}else{
			no_giveup_rejoin= info[0]->BooleanValue();
		}
	}else if(1 < info.Length()){
		if(!info[1]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		no_giveup_rejoin= info[0]->BooleanValue();
		callback		= new Nan::Callback(info[1].As<v8::Function>());
	}

	// work
	if(callback){
		Nan::AsyncQueueWorker(new OpenWorker(callback, &(obj->_chmcntrl), no_giveup_rejoin));
		info.GetReturnValue().Set(Nan::True());
	}else{
		msgid_t	msgid = obj->_chmcntrl.Open(no_giveup_rejoin);
		if(CHM_INVALID_MSGID != msgid){
			info.GetReturnValue().Set(Nan::Encode(&msgid, sizeof(msgid_t), Nan::BINARY));
		}else{
			info.GetReturnValue().SetNull();
		}
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

NAN_METHOD(ChmpxNode::Close)
{
	if(info.Length() < 1){
		Nan::ThrowSyntaxError("No msgid is specified.");
		return;
	}

	ChmpxNode*		obj			= Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());
	msgid_t			msgid;
	char*			ptmpmsgid	= reinterpret_cast<char*>(&msgid);
	Nan::Callback*	callback	= obj->_cbs.Find(stc_emitters[EMITTER_POS_CLOSE]);
	if(1 < info.Length()){
		if(!info[1]->IsFunction()){
			// must callback function is spacified at last pos.
			Nan::ThrowSyntaxError("Last parameter is not callback function.");
			return;
		}
		callback = new Nan::Callback(info[1].As<v8::Function>());
	}
	// msgid
	Nan::DecodeWrite(ptmpmsgid, Nan::DecodeBytes(info[0], Nan::BINARY), info[0], Nan::BINARY);

	// work
	if(callback){
		Nan::AsyncQueueWorker(new CloseWorker(callback, &(obj->_chmcntrl), msgid));
		info.GetReturnValue().Set(Nan::True());
	}else{
		info.GetReturnValue().Set(Nan::New(obj->_chmcntrl.Close(msgid)));
	}
}

/**
 * @memberof ChmpxNode
 * @fn bool isChmpxExit()
 * @brief	Check the chmpx process's status(running or exit)
 *
 * @return	Returns true as chmpx process is running, false means chmpx process does not exist.
 */
NAN_METHOD(ChmpxNode::IsChmpxExit)
{
	ChmpxNode*	obj = Nan::ObjectWrap::Unwrap<ChmpxNode>(info.This());

	info.GetReturnValue().Set(Nan::New(
		obj->_chmcntrl.IsChmpxExit()
	));
}

//@}

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
