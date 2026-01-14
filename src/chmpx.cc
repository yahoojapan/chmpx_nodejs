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

#include <napi.h>
#include "chmpx_node.h"

//---------------------------------------------------------
// chmpx node object
//---------------------------------------------------------
// [NOTE]
// The logic for receiving arguments when switching to N-API has been removed.
// This is because the arguments were not used in the first place and did not
// need to be defined.
//
Napi::Value CreateObject(const Napi::CallbackInfo& info)
{
	Napi::Env env = info.Env();
	return ChmpxNode::NewInstance(env);	// always no arguments.
}

Napi::Object InitAll(Napi::Env env, Napi::Object exports)
{
	// Class registration (creating a constructor)
	ChmpxNode::Init(env, exports);

	// Create a factory function that returns module.exports
	Napi::Function createFn = Napi::Function::New(env, CreateObject, "chmpx");

	// Allow to use "require('chmpx').ChmpxNode"
	createFn.Set("ChmpxNode", ChmpxNode::constructor.Value());

	// Replace module.exports with this function (does not break existing "require('chmpx')()".)
	return createFn;
}

NODE_API_MODULE(chmpx, InitAll)

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
