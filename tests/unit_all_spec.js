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

var	common			= require('./unit_common');				// Common objects for Chai
var	chai			= common.chai;							// eslint-disable-line no-unused-vars
var	chmpxnode		= common.chmpxnode;						// eslint-disable-line no-unused-vars
var	testdir			= common.testdir;						// eslint-disable-line no-unused-vars
var	assert			= common.assert;						// eslint-disable-line no-unused-vars
var	expect			= common.expect;						// eslint-disable-line no-unused-vars
var	subproc			= require('./unit_run_process');		// Utility objects for sub processes
var	startServer		= subproc.startServer;					// eslint-disable-line no-unused-vars
var	startSlaveChmpx	= subproc.startSlaveChmpx;				// eslint-disable-line no-unused-vars
var	startSlaveNode	= subproc.startSlaveNode;				// eslint-disable-line no-unused-vars
var	stopProcs		= subproc.stop;							// eslint-disable-line no-unused-vars

//--------------------------------------------------------------
// Before in global section
//--------------------------------------------------------------
before(function(){										// eslint-disable-line no-undef
	// Nothing to do
});

//--------------------------------------------------------------
// After in global section
//--------------------------------------------------------------
after(function(){										// eslint-disable-line no-undef
	// Nothing to do
});

//--------------------------------------------------------------
// BeforeEach in global section
//--------------------------------------------------------------
beforeEach(function(){									// eslint-disable-line no-undef
	// Nothing to do
});

//--------------------------------------------------------------
// AfterEach in global section
//--------------------------------------------------------------
afterEach(function(){									// eslint-disable-line no-undef
	// Nothing to do
});

//--------------------------------------------------------------
// Main describe section
//--------------------------------------------------------------
describe('ALL TEST', function(){						// eslint-disable-line no-undef
	//
	// Before in describe section
	//
	before(function(){									// eslint-disable-line no-undef
		// Nothing to do
	});

	//
	// After in describe section
	//
	after(function(){									// eslint-disable-line no-undef
		// Nothing to do
	});

	//
	// Sub testing scripts
	//
	describe('SUB TEST: CHMPX SLAVE', function(){		// eslint-disable-line no-undef
		require('./unit_chmpx_slave');
	});

	describe('SUB TEST: CHMPX SERVER', function(){		// eslint-disable-line no-undef
		require('./unit_chmpx_server');
	});
});

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
