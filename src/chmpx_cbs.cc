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

#include <fullock/flckstructure.h>
#include <fullock/flckbaselist.tcc>
#include "chmpx_cbs.h"

using namespace std;
using namespace fullock;

//---------------------------------------------------------
// StackEmitCB Class
//---------------------------------------------------------
StackEmitCB::StackEmitCB() : lockval(FLCK_NOSHARED_MUTEX_VAL_UNLOCKED)
{
}

StackEmitCB::~StackEmitCB()
{
	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK
	EmitCbsMap.clear();
	flck_unlock_noshared_mutex(&lockval);			// UNLOCK
}

bool StackEmitCB::Set(const std::string& emitter, const Napi::Function& cb)
{
	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK

	// clear if existed
	auto it = EmitCbsMap.find(emitter);
	if(EmitCbsMap.end() != it){
		it->second.Reset();
		EmitCbsMap.erase(it);
	}

	// Insert new persistent reference
	Napi::FunctionReference ref = Napi::Persistent(cb);
	EmitCbsMap.emplace(emitter, std::move(ref));

	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return true;
}

bool StackEmitCB::Unset(const std::string& emitter)
{
	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK

	auto it = EmitCbsMap.find(emitter);
	if(EmitCbsMap.end() == it){
		flck_unlock_noshared_mutex(&lockval);		// UNLOCK
		return false;
	}
	it->second.Reset();
	EmitCbsMap.erase(it);

	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return true;
}

Napi::FunctionReference* StackEmitCB::Find(const std::string& emitter)
{
	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK

	auto it = EmitCbsMap.find(emitter);
	if(EmitCbsMap.end() == it){
		flck_unlock_noshared_mutex(&lockval);		// UNLOCK
		return nullptr;
	}
	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return &it->second;
}

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
