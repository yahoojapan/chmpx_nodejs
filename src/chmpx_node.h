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

#ifndef CHMPX_NODE_H
#define CHMPX_NODE_H

#include "chmpx_common.h"
#include "chmpx_cbs.h"

//---------------------------------------------------------
// ChmpxNode Class
//---------------------------------------------------------
class ChmpxNode : public Napi::ObjectWrap<ChmpxNode>
{
	public:
		static void Init(Napi::Env env, Napi::Object exports);
		static Napi::Object NewInstance(Napi::Env env);
		static Napi::Object NewInstance(Napi::Env env, const Napi::Value& arg);

		static Napi::Object GetInstance(const Napi::CallbackInfo& info);

		// Constructor / Destructor
		explicit ChmpxNode(const Napi::CallbackInfo& info);
		~ChmpxNode();

	private:
		Napi::Value New(const Napi::CallbackInfo& info);

		Napi::Value On(const Napi::CallbackInfo& info);
		Napi::Value OnInitializeOnServer(const Napi::CallbackInfo& info);
		Napi::Value OnInitializeOnSlave(const Napi::CallbackInfo& info);
		Napi::Value OnOpen(const Napi::CallbackInfo& info);
		Napi::Value OnClose(const Napi::CallbackInfo& info);
		Napi::Value OnSend(const Napi::CallbackInfo& info);
		Napi::Value OnBroadcast(const Napi::CallbackInfo& info);
		Napi::Value OnReply(const Napi::CallbackInfo& info);
		Napi::Value OnReceive(const Napi::CallbackInfo& info);
		Napi::Value Off(const Napi::CallbackInfo& info);
		Napi::Value OffInitializeOnServer(const Napi::CallbackInfo& info);
		Napi::Value OffInitializeOnSlave(const Napi::CallbackInfo& info);
		Napi::Value OffOpen(const Napi::CallbackInfo& info);
		Napi::Value OffClose(const Napi::CallbackInfo& info);
		Napi::Value OffSend(const Napi::CallbackInfo& info);
		Napi::Value OffBroadcast(const Napi::CallbackInfo& info);
		Napi::Value OffReply(const Napi::CallbackInfo& info);
		Napi::Value OffReceive(const Napi::CallbackInfo& info);

		Napi::Value InitializeOnServer(const Napi::CallbackInfo& info);
		Napi::Value InitializeOnSlave(const Napi::CallbackInfo& info);
		Napi::Value Send(const Napi::CallbackInfo& info);
		Napi::Value Broadcast(const Napi::CallbackInfo& info);
		Napi::Value Receive(const Napi::CallbackInfo& info);
		Napi::Value Reply(const Napi::CallbackInfo& info);
		Napi::Value Open(const Napi::CallbackInfo& info);
		Napi::Value Close(const Napi::CallbackInfo& info);
		Napi::Value IsChmpxExit(const Napi::CallbackInfo& info);

	public:
		// constructor reference
		static Napi::FunctionReference	constructor;

		StackEmitCB	_cbs;

	private:
		ChmCntrl	_chmcntrl;
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
