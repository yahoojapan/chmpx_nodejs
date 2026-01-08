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
 * CREATE:   Wed Jan 7 2026
 * REVISION:
 *
 */

//--------------------------------------------------------------
// Warning Suppression Wrapper
//--------------------------------------------------------------
// This file is a wrapper that enables or disables the 
// "--experimental-loader warning when running tests as follows:
//
//	$ node --loader esm.mjs --experimental-specifier-resolution=node mocha --extensions ts unit_chmpx_server.ts
//	  (node:XXXX) ExperimentalWarning: `--experimental-loader` may be removed in the future; instead use `register()`:
//
//--------------------------------------------------------------

import { register } from 'node:module';
import { pathToFileURL } from 'node:url';

register(new URL('../node_modules/ts-node/esm.mjs', import.meta.url), pathToFileURL('./'));

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
