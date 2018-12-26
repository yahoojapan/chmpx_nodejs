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

#ifndef CHMPX_NODE_H
#define CHMPX_NODE_H

#include "chmpx_common.h"
#include "chmpx_cbs.h"

//---------------------------------------------------------
// ChmpxNode Class
//---------------------------------------------------------
class ChmpxNode : public Nan::ObjectWrap
{
	public:
		static void	Init(void);
		static NAN_METHOD(NewInstance);
		static v8::Local<v8::Object> GetInstance(Nan::NAN_METHOD_ARGS_TYPE info);

	private:
		ChmpxNode(void);
		~ChmpxNode(void);

		static NAN_METHOD(New);

		static NAN_METHOD(On);
		static NAN_METHOD(OnInitializeOnServer);
		static NAN_METHOD(OnInitializeOnSlave);
		static NAN_METHOD(OnOpen);
		static NAN_METHOD(OnClose);
		static NAN_METHOD(OnSend);
		static NAN_METHOD(OnBroadcast);
		static NAN_METHOD(OnReply);
		static NAN_METHOD(OnReceive);
		static NAN_METHOD(Off);
		static NAN_METHOD(OffInitializeOnServer);
		static NAN_METHOD(OffInitializeOnSlave);
		static NAN_METHOD(OffOpen);
		static NAN_METHOD(OffClose);
		static NAN_METHOD(OffSend);
		static NAN_METHOD(OffBroadcast);
		static NAN_METHOD(OffReply);
		static NAN_METHOD(OffReceive);

		static NAN_METHOD(InitializeOnServer);
		static NAN_METHOD(InitializeOnSlave);
		static NAN_METHOD(Send);
		static NAN_METHOD(Broadcast);
		static NAN_METHOD(Receive);
		static NAN_METHOD(Reply);
		static NAN_METHOD(Open);
		static NAN_METHOD(Close);
		static NAN_METHOD(IsChmpxExit);

	private:
		static Nan::Persistent<v8::Function>	constructor;
		ChmCntrl								_chmcntrl;
		StackEmitCB								_cbs;
};

#endif

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
