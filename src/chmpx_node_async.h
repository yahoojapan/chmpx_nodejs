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
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, const char* pfile, bool is_auto, bool is_on_server)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class InitializeOnWorker : public Nan::AsyncWorker
{
	public:
		InitializeOnWorker(Nan::Callback* callback, ChmCntrl* pobj, const char* pfile, bool is_auto, bool is_on_server) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), filename(pfile ? pfile : ""), is_auto_rejoin(is_auto), is_server(is_on_server) {}
		~InitializeOnWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			pchmpxcntrl->Clean();
			bool	result;
			if(is_server){
				result = pchmpxcntrl->InitializeOnServer(filename.c_str(), is_auto_rejoin);
			}else{
				result = pchmpxcntrl->InitializeOnSlave(filename.c_str(), is_auto_rejoin);
			}
			if(!result){
				// set error
				this->SetErrorMessage("Failed to initialize chmpx object on server.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*	pchmpxcntrl;
		std::string	filename;
		bool		is_auto_rejoin;
		bool		is_server;
};

//---------------------------------------------------------
// OpenWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, bool no_giveup)
// Callback function:	function(string error[, msgid_t msgid]])
//
//---------------------------------------------------------
class OpenWorker : public Nan::AsyncWorker
{
	public:
		OpenWorker(Nan::Callback* callback, ChmCntrl* pobj, bool no_giveup) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), no_giveup_rejoin(no_giveup), msgid(CHM_INVALID_MSGID) {}
		~OpenWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			if(CHM_INVALID_MSGID == (msgid = pchmpxcntrl->Open(no_giveup_rejoin))){
				// set error
				this->SetErrorMessage("Failed to open msgid.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 2;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null(), Nan::Encode(&msgid, sizeof(msgid_t), Nan::BINARY) };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*	pchmpxcntrl;
		bool		no_giveup_rejoin;
		msgid_t		msgid;
};

//---------------------------------------------------------
// CloseWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, msgid_t msgid)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class CloseWorker : public Nan::AsyncWorker
{
	public:
		CloseWorker(Nan::Callback* callback, ChmCntrl* pobj, msgid_t msgid) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), close_msgid(msgid) {}
		~CloseWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			if(false == pchmpxcntrl->Close(close_msgid)){
				// set error
				this->SetErrorMessage("Failed to close msgid.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*	pchmpxcntrl;
		msgid_t		close_msgid;
};

//---------------------------------------------------------
// SendWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash, bool is_routing)
// Callback function:	function(string error[, int receivercount])
//
//---------------------------------------------------------
class SendWorker : public Nan::AsyncWorker
{
	public:
		SendWorker(Nan::Callback* callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash, bool is_routing) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), msgid(send_msgid), pbin(pbinptr), length(binsize), hash(binhash), routing(is_routing), recievercnt(-1) {}
		~SendWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			recievercnt	= 0;
			if(!pchmpxcntrl->Send(msgid, pbin, length, hash, &recievercnt, routing)){
				// set error
				this->SetErrorMessage("Failed to send data.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 2;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null(), Nan::New<v8::Integer>(static_cast<int32_t>(recievercnt)) };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*		pchmpxcntrl;
		msgid_t			msgid;
		unsigned char*	pbin;
		ssize_t			length;
		chmhash_t		hash;
		bool			routing;
		long			recievercnt;
};

//---------------------------------------------------------
// BroadcastWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash)
// Callback function:	function(string error[, int receivercount])
//
//---------------------------------------------------------
class BroadcastWorker : public Nan::AsyncWorker
{
	public:
		BroadcastWorker(Nan::Callback* callback, ChmCntrl* pobj, msgid_t send_msgid, unsigned char* pbinptr, ssize_t binsize, chmhash_t binhash) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), msgid(send_msgid), pbin(pbinptr), length(binsize), hash(binhash), recievercnt(-1) {}
		~BroadcastWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			recievercnt	= 0;
			if(!pchmpxcntrl->Broadcast(msgid, pbin, length, hash, &recievercnt)){
				// set error
				this->SetErrorMessage("Failed to broadcast data.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 2;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null(), Nan::New<v8::Integer>(static_cast<int32_t>(recievercnt)) };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*		pchmpxcntrl;
		msgid_t			msgid;
		unsigned char*	pbin;
		ssize_t			length;
		chmhash_t		hash;
		long			recievercnt;
};

//---------------------------------------------------------
// ReplyWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, PCOMPKT compkt, unsigned char* pbinptr, ssize_t binsize)
// Callback function:	function(string error)
//
//---------------------------------------------------------
class ReplyWorker : public Nan::AsyncWorker
{
	public:
		ReplyWorker(Nan::Callback* callback, ChmCntrl* pobj, PCOMPKT compkt, unsigned char* pbinptr, ssize_t binsize) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), pComPkt(compkt), pbin(pbinptr), length(binsize) {}
		~ReplyWorker() {}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}
			if(!pchmpxcntrl->Reply(pComPkt, pbin, length)){
				// set error
				this->SetErrorMessage("Failed to broadcast data.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*		pchmpxcntrl;
		PCOMPKT			pComPkt;
		unsigned char*	pbin;
		ssize_t			length;
};

//---------------------------------------------------------
// ReceiveWorker class
//
// Constructor:			constructor(Nan::Callback* callback, ChmCntrl* pobj, int timeout, bool no_giveup)
// 						constructor(Nan::Callback* callback, ChmCntrl* pobj, msgid_t rcv_msgid, int timeout)
// Callback function:	function(string error[, binary compkt, buffer data])
//
//---------------------------------------------------------
class ReceiveWorker : public Nan::AsyncWorker
{
	public:
		ReceiveWorker(Nan::Callback* callback, ChmCntrl* pobj, int timeout, bool no_giveup) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), is_on_server(true), msgid(CHM_INVALID_MSGID), timeout_ms(timeout), no_giveup_rejoin(no_giveup), pComPkt(NULL), pBody(NULL), Length(0) {}
		ReceiveWorker(Nan::Callback* callback, ChmCntrl* pobj, msgid_t rcv_msgid, int timeout) : Nan::AsyncWorker(callback), pchmpxcntrl(pobj), is_on_server(false), msgid(rcv_msgid), timeout_ms(timeout), no_giveup_rejoin(false), pComPkt(NULL), pBody(NULL), Length(0) {}
		~ReceiveWorker()
		{
			CHM_Free(pComPkt);
			CHM_Free(pBody);
		}

		void Execute()
		{
			if(!pchmpxcntrl){
				Nan::ReferenceError("No object is associated to async worker");
				return;
			}

			// receive
			bool	result;
			if(is_on_server){
				result = pchmpxcntrl->Receive(&pComPkt, &pBody, &Length, timeout_ms, no_giveup_rejoin);
			}else{
				result = pchmpxcntrl->Receive(msgid, &pComPkt, &pBody, &Length, timeout_ms);
			}
			if(!result || !pComPkt || !pBody || 0 == Length){
				// set error
				this->SetErrorMessage("Failed to receive data.");
			}
		}

		void HandleOKCallback()
		{
			Nan::HandleScope		scope;
			const int				argc		= 3;
			v8::Local<v8::Value>	argv[argc]	= { Nan::Null(), Nan::Encode(pComPkt, sizeof(COMPKT), Nan::BINARY), Nan::Encode(pBody, Length, Nan::BUFFER) };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
		}

        void HandleErrorCallback()
        {
			Nan::HandleScope		scope;
			const int				argc		= 1;
			v8::Local<v8::Value>	argv[argc]	= { Nan::New<v8::String>(this->ErrorMessage()).ToLocalChecked() };

			if(callback){
				callback->Call(argc, argv);
			}else{
				Nan::ThrowSyntaxError("Internal error in async worker");
				return;
			}
        }

	private:
		ChmCntrl*		pchmpxcntrl;
		bool			is_on_server;
		msgid_t			msgid;
		int				timeout_ms;
		bool			no_giveup_rejoin;
		PCOMPKT			pComPkt;
		unsigned char*	pBody;
		size_t			Length;
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
