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
 * AUTHOR:   Taku Ishihara
 * CREATE:   Mon Oct 31 2016
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
// Main describe section
//--------------------------------------------------------------
describe('CHMPX SERVER', function(){						// eslint-disable-line no-undef
	//
	// Global
	//
	var chmpxserverobj	= null;
//	var	msgid1			= null;
//	var	msgid2			= null;

	//
	// Before in describe section
	//
	before(function(done){								// eslint-disable-line no-undef
		startSlaveChmpx(this, testdir);
		chmpxserverobj = new chmpxnode();
		done();
	});

	//
	// After in describe section
	//
	after(function(done){								// eslint-disable-line no-undef
		stopProcs(this, testdir);
		done();
	});

	//-------------------------------------------------------------------
	// Test Server side
	//-------------------------------------------------------------------
	//
	// ChmpxNode::initializeOnServer() - No Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - No Callback', function(done){			// eslint-disable-line no-undef
		// No initializing callback
		expect(typeof chmpxserverobj).to.equal('object');
		expect(chmpxserverobj.isChmpxExit()).to.be.a('boolean').to.be.false;
		expect(chmpxserverobj.initializeOnServer(testdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;

		done();
	});

	//
	// ChmpxNode::initializeOnServer() - on Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - on Callback', function(done){			// eslint-disable-line no-undef
		// Registered initializing callback
		expect(chmpxserverobj.on('initializeOnServer', function(error)
		{
			expect(error).to.be.null;
			chmpxserverobj.off('initializeOnServer');

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxserverobj.initializeOnServer(testdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnServer() - onInitializeOnSever Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - onInitializeOnSever Callback', function(done){	// eslint-disable-line no-undef
		// Registered initializing callback
		expect(chmpxserverobj.onInitializeOnServer(function(error)
		{
			expect(error).to.be.null;
			chmpxserverobj.offInitializeOnServer();

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxserverobj.initializeOnServer(testdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnServer() - inline Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - inline Callback', function(done){		// eslint-disable-line no-undef
		// Inline initializing Callback
		expect(chmpxserverobj.initializeOnServer(testdir + '/chmpx_server.ini', true, function(error)
		{
			expect(error).to.be.null;

			done();
		})).to.be.a('boolean').to.be.true;
	});

	//
	// Run processes(node chmpx slave)
	//
	it('Server test - RUN PROCESSES(TEST SLAVE NODE)', function(done){							// eslint-disable-line no-undef
		startSlaveNode(this, testdir);
		done();
	});

	//
	// ChmpxNode::receive() - Broadcast
	//
	it('Server test - ChmpxNode::receive() - Broadcast', function(done){						// eslint-disable-line no-undef
		while(true){
			var outarr = new Array();

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				var receive_str = outarr[1].toString();
				expect(receive_str).to.equal('Broadcast message.');

				var replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - japanese(utf-8)
	//
	it('Server test - ChmpxNode::receive() - japanese(utf-8)', function(done){					// eslint-disable-line no-undef
		while(true){
			var outarr = new Array();

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				var receive_str = outarr[1].toString();
				expect(receive_str).to.equal('センドレシーブ');

				var replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - japanese(utf-8: special words)
	//
	it('Server test - ChmpxNode::receive() - japanese(utf-8: special words)', function(done){	// eslint-disable-line no-undef
		while(true){
			var outarr = new Array();

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				var target_str	= Buffer.from([0xE2,0x87,0x92,0xE3,0x8C,0xAB]);
				expect(Buffer.compare(outarr[1], target_str)).to.equal(0);

				var replydata = Buffer.from('Reply(' + outarr[1].toString() + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - normal
	//
	it('Server test - ChmpxNode::receive() - normal', function(done){						// eslint-disable-line no-undef
		while(true){
			var outarr = new Array();

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				var receive_str	= outarr[1].toString();
				expect(receive_str).to.equal('send receive.');

				var replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - break
	//
	it('Server test - ChmpxNode::receive() - break', function(done){						// eslint-disable-line no-undef
		while(true){
			var outarr = new Array();

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				var receive_str	= outarr[1].toString();
				expect(receive_str).to.equal('BREAK TEST');

				break;
			}
		}
		done();
	});

	//
	// Read rest messages
	//
	it('Server test - Delete ChmpxNode object', function(done){								// eslint-disable-line no-undef
		// get rest data if exists
		while(true){
			var outarr = new Array();
			if(!chmpxserverobj.receive(outarr, 500) || 0 == outarr[1].length){
				break;
			}
		}
		done();
	});
});

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
