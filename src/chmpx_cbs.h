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

#ifndef CHMPX_CBS_H
#define CHMPX_CBS_H

#include <string>
#include <unordered_map>
#include "chmpx_common.h"

//---------------------------------------------------------
// Typedefs
//---------------------------------------------------------
typedef std::unordered_map<std::string, Napi::FunctionReference>	cbsmap;

//---------------------------------------------------------
// StackEmitCB Class
//---------------------------------------------------------
class StackEmitCB
{
	public:
		StackEmitCB();
		virtual ~StackEmitCB();

		// Set returns true if set succeeded
		bool Set(const std::string& emitter, const Napi::Function& cb);

		// Unset returns true if removed
		bool Unset(const std::string& emitter);

		// Find returns pointer to FunctionReference if set, otherwise nullptr
		Napi::FunctionReference* Find(const std::string& emitter);

	protected:
		cbsmap			EmitCbsMap;
		volatile int	lockval;				// lock variable for mapping
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
