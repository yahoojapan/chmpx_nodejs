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
 * AUTHOR:   Takeshi Nakatani
 * CREATE:   Mon Feb 27 2017
 * REVISION:
 *
 */

#include <fullock/flckstructure.h>
#include <fullock/flckbaselist.tcc>
#include "chmpx_cbs.h"

using namespace v8;
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

// [NOTE]
// This method does not lock, thus must lock before calling this.
//
Nan::Callback* StackEmitCB::RawFind(const char* pemitname)
{
	string			stremit	= pemitname ? pemitname : "";
	Nan::Callback*	cbfunc	= NULL;
	if(stremit.empty()){
		return cbfunc;
	}
	if(EmitCbsMap.end() != EmitCbsMap.find(stremit)){
		cbfunc = EmitCbsMap[stremit];
	}
	return cbfunc;
}

Nan::Callback* StackEmitCB::Find(const char* pemitname)
{
	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK
	Nan::Callback*	cbfunc = RawFind(pemitname);
	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return cbfunc;
}

bool StackEmitCB::Set(const char* pemitname, Nan::Callback* cbfunc)
{
	string	stremit = pemitname ? pemitname : "";
	if(stremit.empty()){
		return false;
	}

	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK

	Nan::Callback*	oldcbfunc = RawFind(pemitname);
	if(oldcbfunc){
		EmitCbsMap.erase(stremit);
	}
	if(cbfunc){
		EmitCbsMap[stremit] = cbfunc;
	}
	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return true;
}

bool StackEmitCB::Unset(const char* pemitname)
{
	string	stremit = pemitname ? pemitname : "";
	if(stremit.empty()){
		return false;
	}

	while(!flck_trylock_noshared_mutex(&lockval));	// LOCK

	Nan::Callback*	oldcbfunc = RawFind(pemitname);
	if(oldcbfunc){
		EmitCbsMap.erase(stremit);
	}
	flck_unlock_noshared_mutex(&lockval);			// UNLOCK

	return true;
}

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
