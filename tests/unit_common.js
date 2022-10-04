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
 * CREATE:   Thu Nov 8 2018
 * REVISION:
 *
 */

'use strict';

//
// Common Chai objects for each test modules.
//
var chai			= require('chai');
var chmpxnode		= require('chmpx');
var	testdirpath		= __dirname;

//
// Exports
//
exports.chai		= chai;
exports.chmpxnode	= chmpxnode;
exports.testdir		= testdirpath;
exports.assert		= chai.assert;
exports.expect		= chai.expect;

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
