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

#ifndef CHMPX_COMMON_H
#define CHMPX_COMMON_H

//---------------------------------------------------------
// common headers
//---------------------------------------------------------
#include <node.h>
#include <chmpx/chmcntrl.h>
#include <chmpx/chmkvp.h>
#include <chmpx/chmpx.h>

#include <nan.h>

#include <string>
#include <iostream>
#include <map>

#endif

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
