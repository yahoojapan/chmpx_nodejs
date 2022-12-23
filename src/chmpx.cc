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

using namespace v8;

//---------------------------------------------------------
// chmpx node object
//---------------------------------------------------------
NAN_METHOD(CreateObject)
{
	ChmpxNode::NewInstance(info);
}

void InitAll(Local<Object> exports, Local<Object> module)
{
	ChmpxNode::Init();
	Nan::Set(module, Nan::New("exports").ToLocalChecked(), Nan::GetFunction(Nan::New<FunctionTemplate>(CreateObject)).ToLocalChecked());
}

NODE_MODULE(chmpx, InitAll)

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
