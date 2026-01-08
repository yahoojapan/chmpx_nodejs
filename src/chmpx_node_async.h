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
 * AUTHOR:   Takeshi Nakatani
 * CREATE:   Mon Feb 27 2017
 * REVISION:
 *
 */

#ifndef CHMPX_NODE_AYNC_H
#define CHMPX_NODE_AYNC_H

#include "chmpx_common.h"

//
// AsyncWorker classes for using ChmpxNode
//

//---------------------------------------------------------
// InitializeOnWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, const std::string& filename, bool is_auto, bool is_on_server)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class InitializeOnWorker : public Napi::AsyncWorker
{
	public:
		InitializeOnWorker(const Napi::Function& callback, ChmCntrl* pobj, const std::string& filename, bool is_auto, bool is_on_server) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _filename(filename), _is_auto_rejoin(is_auto), _is_server(is_on_server)
		{
			_callbackRef.Ref();
		}

		~InitializeOnWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			_chmpxcntrl->Clean();
			if(_is_server){
				if(!_chmpxcntrl->InitializeOnServer(_filename.c_str(), _is_auto_rejoin)){
					SetError(std::string("Failed to initialize chmpx object on server: ") + _filename);	// call SetError method in Napi::AsyncWorker
					return;
				}
			}else{
				if(!_chmpxcntrl->InitializeOnSlave(_filename.c_str(), _is_auto_rejoin)){
					SetError(std::string("Failed to initialize chmpx object on slave: ") + _filename);	// call SetError method in Napi::AsyncWorker
					return;
				}
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null() });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		std::string				_filename;
		bool					_is_auto_rejoin;
		bool					_is_server;
};

//---------------------------------------------------------
// OpenWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, bool no_giveup)
// Callback function:	function(string error[, msgid_t msgid]])
//
//---------------------------------------------------------
class OpenWorker : public Napi::AsyncWorker
{
	public:
		OpenWorker(const Napi::Function& callback, ChmCntrl* pobj, bool no_giveup) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _no_giveup_rejoin(no_giveup), _msgid(CHM_INVALID_MSGID)
		{
			_callbackRef.Ref();
		}

		~OpenWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			if(CHM_INVALID_MSGID == (_msgid = _chmpxcntrl->Open(_no_giveup_rejoin))){
				SetError(std::string("Failed to open msgid."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null(), Napi::Buffer<char>::Copy(Env(), reinterpret_cast<char*>(&_msgid), static_cast<size_t>(sizeof(_msgid))) });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		bool					_no_giveup_rejoin;
		msgid_t					_msgid;
};

//---------------------------------------------------------
// CloseWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, msgid_t msgid)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class CloseWorker : public Napi::AsyncWorker
{
	public:
		CloseWorker(const Napi::Function& callback, ChmCntrl* pobj, msgid_t msgid) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _close_msgid(msgid)
		{
			_callbackRef.Ref();
		}

		~CloseWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			if(false == _chmpxcntrl->Close(_close_msgid)){
				SetError(std::string("Failed to close msgid."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null() });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		msgid_t					_close_msgid;
};

//---------------------------------------------------------
// SendWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash, bool is_routing)
// Callback function:	function(string error[, int receivercount])
//
//---------------------------------------------------------
class SendWorker : public Napi::AsyncWorker
{
	public:
		SendWorker(const Napi::Function& callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash, bool is_routing) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _msgid(send_msgid), _pbin(pbinptr), _length(binsize), _hash(binhash), _routing(is_routing), _recievercnt(-1)
		{
			_callbackRef.Ref();
		}

		~SendWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			_recievercnt	= 0;
			if(!_chmpxcntrl->Send(_msgid, _pbin, _length, _hash, &_recievercnt, _routing)){
				SetError(std::string("Failed to send data."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null(), Napi::Number::New(env, static_cast<int32_t>(_recievercnt)) });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		msgid_t					_msgid;
		unsigned char*			_pbin;
		ssize_t					_length;
		chmhash_t				_hash;
		bool					_routing;
		long					_recievercnt;
};

//---------------------------------------------------------
// BroadcastWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash)
// Callback function:	function(string error[, int receivercount])
//
//---------------------------------------------------------
class BroadcastWorker : public Napi::AsyncWorker
{
	public:
		BroadcastWorker(const Napi::Function& callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _msgid(send_msgid), _pbin(pbinptr), _length(binsize), _hash(binhash), _recievercnt(-1)
		{
			_callbackRef.Ref();
		}

		~BroadcastWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			_recievercnt	= 0;
			if(!_chmpxcntrl->Broadcast(_msgid, _pbin, _length, _hash, &_recievercnt)){
				SetError(std::string("Failed to broadcast data."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null(), Napi::Number::New(env, static_cast<int32_t>(_recievercnt)) });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		msgid_t					_msgid;
		unsigned char*			_pbin;
		ssize_t					_length;
		chmhash_t				_hash;
		long					_recievercnt;
};

//---------------------------------------------------------
// ReplyWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, PCOMPKT compkt, unsigned char* pbinptr, ssize_t binsize)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class ReplyWorker : public Napi::AsyncWorker
{
	public:
		ReplyWorker(const Napi::Function& callback, ChmCntrl* pobj, PCOMPKT compkt, unsigned char* pbinptr, ssize_t binsize) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _pComPkt(compkt), _pbin(pbinptr), _length(binsize)
		{
			_callbackRef.Ref();
		}

		~ReplyWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			if(!_chmpxcntrl->Reply(_pComPkt, _pbin, _length)){
				SetError(std::string("Failed to broadcast data."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ env.Null() });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		PCOMPKT					_pComPkt;
		unsigned char*			_pbin;
		ssize_t					_length;
};

//---------------------------------------------------------
// ReceiveWorker class
//
// Constructor:			constructor(const Napi::Function& callback, ChmCntrl* pobj, int timeout, bool no_giveup)
// 						constructor(const Napi::Function& callback, ChmCntrl* pobj, msgid_t rcv_msgid, int timeout)
// Callback function:	function(string error[, binary compkt, buffer data])
//
//---------------------------------------------------------
class ReceiveWorker : public Napi::AsyncWorker
{
	public:
		ReceiveWorker(const Napi::Function& callback, ChmCntrl* pobj, int timeout, bool no_giveup) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _is_server(true), _msgid(CHM_INVALID_MSGID), _timeout_ms(timeout), _no_giveup_rejoin(no_giveup), _pComPkt(NULL), _pBody(NULL), _length(0)
		{
			_callbackRef.Ref();
		}

		ReceiveWorker(const Napi::Function& callback, ChmCntrl* pobj, msgid_t rcv_msgid, int timeout) :
			Napi::AsyncWorker(callback), _callbackRef(Napi::Persistent(callback)), _chmpxcntrl(pobj), _is_server(false), _msgid(rcv_msgid), _timeout_ms(timeout), _no_giveup_rejoin(false), _pComPkt(NULL), _pBody(NULL), _length(0)
		{
			_callbackRef.Ref();
		}

		~ReceiveWorker() override
		{
			if(_callbackRef){
				_callbackRef.Unref();
				_callbackRef.Reset();
			}
			CHM_Free(_pComPkt);
			CHM_Free(_pBody);
		}

		// Run on worker thread
		void Execute() override
		{
			if(!_chmpxcntrl){
				SetError("No object is associated to async worker");
				return;
			}

			// receive
			bool	result;
			if(_is_server){
				result = _chmpxcntrl->Receive(&_pComPkt, &_pBody, &_length, _timeout_ms, _no_giveup_rejoin);
			}else{
				result = _chmpxcntrl->Receive(_msgid, &_pComPkt, &_pBody, &_length, _timeout_ms);
			}
			if(!result || !_pComPkt || !_pBody || 0 == _length){
				SetError(std::string("Failed to receive data."));
				return;
			}
		}

		// handler for success
		void OnOK() override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is null and the second argument is the result.
			if(!_callbackRef.IsEmpty()){
				Napi::Value	pktBuf	= Napi::Buffer<char>::Copy(env, reinterpret_cast<char*>(_pComPkt), static_cast<size_t>(sizeof(COMPKT)));
				Napi::Value	bodyBuf	= Napi::Buffer<char>::Copy(env, reinterpret_cast<char*>(_pBody), static_cast<size_t>(_length));
				_callbackRef.Value().Call({ env.Null(), pktBuf, bodyBuf });
			}else{
				Napi::TypeError::New(env, "Internal error in async worker").ThrowAsJavaScriptException();
			}
		}

		// handler for failure (by calling SetError)
		void OnError(const Napi::Error& err) override
		{
			Napi::Env env = Env();
			Napi::HandleScope scope(env);

			// The first argument is the error message.
			if(!_callbackRef.IsEmpty()){
				_callbackRef.Value().Call({ Napi::String::New(env, err.Value().ToString().Utf8Value()) });
			}else{
				// Throw error
				err.ThrowAsJavaScriptException();
			}
		}

	private:
		Napi::FunctionReference	_callbackRef;
		ChmCntrl*				_chmpxcntrl;
		bool					_is_server;
		msgid_t					_msgid;
		int						_timeout_ms;
		bool					_no_giveup_rejoin;
		PCOMPKT					_pComPkt;
		unsigned char*			_pBody;
		size_t					_length;
};

#endif

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
