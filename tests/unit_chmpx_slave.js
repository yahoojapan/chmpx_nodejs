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
describe('CHMPX SLAVE', function(){						// eslint-disable-line no-undef
	//
	// Global
	//
	var chmpxslaveobj	= null;
	var	msgid1			= null;
	var	msgid2			= null;

	//
	// Before in describe section
	//
	before(function(done){								// eslint-disable-line no-undef
		startServer(this, testdir);
		chmpxslaveobj = new chmpxnode();
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
	// Test Slave side
	//-------------------------------------------------------------------
	//
	// ChmpxNode::initializeOnServer() - No Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - No Callback', function(done){						// eslint-disable-line no-undef
		// No initializing callback
		expect(typeof chmpxslaveobj).to.equal('object');
		expect(chmpxslaveobj.isChmpxExit()).to.be.a('boolean').to.be.false;
		expect(chmpxslaveobj.initializeOnSlave(testdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;
		done();
	});

	//
	// ChmpxNode::initializeOnSlave() - on Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - on Callback', function(done){						// eslint-disable-line no-undef
		// Registered initializing callback
		expect(chmpxslaveobj.on('initializeOnSlave', function(error)
		{
			expect(error).to.be.null;
			chmpxslaveobj.off('initializeOnSlave');
			done();
		})).to.be.a('boolean').to.be.true;
		expect(chmpxslaveobj.initializeOnSlave(testdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnSlave() - onInitializeOnSever Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - onInitializeOnSever Callback', function(done){						// eslint-disable-line no-undef
		// Registered initializing callback
		expect(chmpxslaveobj.onInitializeOnSlave(function(error)
		{
			expect(error).to.be.null;
			chmpxslaveobj.offInitializeOnSlave();
			done();
		})).to.be.a('boolean').to.be.true;
		expect(chmpxslaveobj.initializeOnSlave(testdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnSlave() - inline Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - inline Callback', function(done){						// eslint-disable-line no-undef
		// Inline initializing Callback
		expect(chmpxslaveobj.initializeOnSlave(testdir + '/chmpx_slave.ini', true, function(error)
		{
			expect(error).to.be.null;
			done();
		})).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::open(), close() - on Callback
	//
	it('Slave test - ChmpxNode::open(), close() - on Callback', function(done){						// eslint-disable-line no-undef
		expect(chmpxslaveobj.on('open', function(error, msgid)
		{
			expect(error).to.be.null;

			// close test
			expect(chmpxslaveobj.on('close', function(error)
			{
				expect(error).to.be.null;

				// unset
				chmpxslaveobj.off('close');
				done();
			})).to.be.a('boolean').to.be.true;

			expect(chmpxslaveobj.close(msgid)).to.be.a('boolean').to.be.true;

			// unset
			chmpxslaveobj.off('open');
		})).to.be.a('boolean').to.be.true;

		expect(chmpxslaveobj.open()).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::open(), close() - onOpen Callback
	//
	it('Slave test - ChmpxNode::open(), close() - onOpen Callback', function(done){						// eslint-disable-line no-undef
		expect(chmpxslaveobj.onOpen(function(error, msgid)
		{
			expect(error).to.be.null;

			// close test
			expect(chmpxslaveobj.onClose(function(error)
			{
				expect(error).to.be.null;

				// unset
				chmpxslaveobj.offClose();

				done();
			})).to.be.a('boolean').to.be.true;

			expect(chmpxslaveobj.close(msgid)).to.be.a('boolean').to.be.true;

			// unset
			chmpxslaveobj.offOpen();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxslaveobj.open()).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::open(), close() - inline Callback
	//
	it('Slave test - ChmpxNode::open(), close() - inline Callback', function(done){						// eslint-disable-line no-undef
		expect(chmpxslaveobj.open(function(error, msgid)
		{
			expect(error).to.be.null;

			// close
			expect(chmpxslaveobj.close(msgid, function(error)
			{
				expect(error).to.be.null;
				done();
			})).to.be.a('boolean').to.be.true;
		})).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::open() - No Callback
	//
	// (Last opened two msgid is permanent for testing after this.)
	//
	it('Slave test - ChmpxNode::open() - No Callback', function(done){						// eslint-disable-line no-undef
		msgid1 = chmpxslaveobj.open();
		msgid2 = chmpxslaveobj.open();
		expect(msgid1).to.not.be.null;
		expect(msgid2).to.not.be.null;
		done();
	});

	//
	// ChmpxNode::send(), receive() - No Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - No Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'))).to.not.equal(-1);

		// receive
		var buffarr = new Array();
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);

		done();
	});

	//
	// ChmpxNode::send(), receive() - on Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - on Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// set for send
		expect(chmpxslaveobj.on('send', function(error, receivecount)
		{
			expect(error).to.be.null;

			// set for receive
			expect(chmpxslaveobj.on('receive', function(error, compkt, data)
			{
				expect(error).to.be.null;
				expect(data).to.not.be.null;
				expect(data.toString()).to.equal('Reply(send receive.)');

				// unset for receive
				chmpxslaveobj.off('receive');

				done();
			})).to.be.a('boolean').to.be.true;

			// receive
			var buffarr = new Array();
			expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;

			// unset for send
			chmpxslaveobj.off('send');
		})).to.be.a('boolean').to.be.true;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'))).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::send(), receive() - onSend/onReceive Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - onSend/onReceive Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// set for send
		expect(chmpxslaveobj.onSend(function(error, receivecount)
		{
			expect(error).to.be.null;

			// set for receive
			expect(chmpxslaveobj.onReceive(function(error, compkt, data)
			{
				expect(error).to.be.null;
				expect(data).to.not.be.null;
				expect(data.toString()).to.equal('Reply(send receive.)');

				// unset for receive
				chmpxslaveobj.off('receive');

				done();
			})).to.be.a('boolean').to.be.true;

			// receive
			var buffarr = new Array();
			expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;

			// unset for send
			chmpxslaveobj.off('send');
		})).to.be.a('boolean').to.be.true;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'))).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::send(), receive() - inline Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - inline Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'), function(error, receivecount)
		{
			expect(error).to.be.null;

			// receive
			expect(chmpxslaveobj.receive(msgid1, 1000, function(error, compkt, data)
			{
				expect(error).to.be.null;
				expect(data).to.not.be.null;
				expect(data.toString()).to.equal('Reply(send receive.)');

				done();
			})).to.be.a('boolean').to.be.true;
		})).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::broadcast(), receive() - No Callback
	//
	it('Slave test - ChmpxNode::broadcast(), receive() - No Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// broadcast
		var	recievercnt = chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'));
		expect(recievercnt).to.not.equal(-1);

		// receive
		for(; 0 < recievercnt; --recievercnt){
			var buffarr = new Array();
			expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
			expect(buffarr.length).to.equal(2);
		}
		done();
	});

	//
	// ChmpxNode::broadcast(), receive() - on Callback
	//
	it('Slave test - ChmpxNode::broadcast(), receive() - on Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// set for broadcast
		expect(chmpxslaveobj.on('broadcast', function(error, receivecount)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				var buffarr = new Array();
				expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;
			}

			// unset for receive
			chmpxslaveobj.off('receive');

			// unset for broadcast
			chmpxslaveobj.off('broadcast');
		})).to.be.a('boolean').to.be.true;

		// set for receive
		expect(chmpxslaveobj.on('receive', function(error, compkt, data)
		{
			expect(error).to.be.null;
			expect(data).to.not.be.null;
			expect(data.toString()).to.equal('Reply(broadcast receive.)');

			done();
		})).to.be.a('boolean').to.be.true;

		// broadcast
		expect(chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'))).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::broadcast(), receive() - onBroadcast/onReceive Callback
	//
	it('Slave test - ChmpxNode::broadcast(), receive() - onBroadcast/onReceive Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// set for broadcast
		expect(chmpxslaveobj.onBroadcast(function(error, receivecount)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				var buffarr = new Array();
				expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;
			}

			// unset for receive
			chmpxslaveobj.off('receive');

			// unset for broadcast
			chmpxslaveobj.off('broadcast');
		})).to.be.a('boolean').to.be.true;

		// set for receive
		expect(chmpxslaveobj.onReceive(function(error, compkt, data)
		{
			expect(error).to.be.null;
			expect(data).to.not.be.null;
			expect(data.toString()).to.equal('Reply(broadcast receive.)');

			done();
		})).to.be.a('boolean').to.be.true;

		// broadcast
		expect(chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'))).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::broadcast(), receive() - inline Callback
	//
	it('Slave test - ChmpxNode::broadcast(), receive() - inline Callback', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// broadcast
		expect(chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'), function(error, receivecount)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				expect(chmpxslaveobj.receive(msgid1, 1000, function(error, compkt, data)
				{
					expect(error).to.be.null;
					expect(data).to.not.be.null;
					expect(data.toString()).to.equal('Reply(broadcast receive.)');

					done();
				})).to.be.a('boolean').to.be.true;
			}
		})).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::send() - japanese
	//
	it('Slave test - ChmpxNode::send() - japanese', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('センドレシーブ'))).to.not.equal(-1);

		// receive
		var buffarr = new Array();
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);
		expect(buffarr[1].toString()).to.equal('Reply(センドレシーブ)');
		done();
	});

	//
	// ChmpxNode::send() - special japanese
	//
	it('Slave test - ChmpxNode::send() - special japanese', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// send
		var target_str = Buffer.from([0xE2,0x87,0x92,0xE3,0x8C,0xAB]);
		expect(chmpxslaveobj.send(msgid1, target_str)).to.not.equal(-1);

		// receive
		var buffarr = new Array();
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);

		var receive_str	= 'Reply(' + target_str + ')';
		expect(buffarr[1].toString()).to.equal(receive_str);

		done();
	});

	//
	// ChmpxNode::send() - error after closing msgid
	//
	it('Slave test - ChmpxNode::send() - error after closing msgid', function(done){						// eslint-disable-line no-undef
		expect(msgid1).to.not.be.null;

		// close
		expect(chmpxslaveobj.close(msgid1)).to.be.a('boolean').to.be.true;

		// send after closing
		expect(chmpxslaveobj.send(msgid1, Buffer.from('msgid1: after Close()'))).to.equal(-1);

		done();
	});

	//
	// ChmpxNode::close() - normal
	//
	it('Slave test - ChmpxNode::close() - normal', function(done){						// eslint-disable-line no-undef
		expect(msgid2).to.not.be.null;
		expect(chmpxslaveobj.close(msgid2)).to.be.a('boolean').to.be.true;

		done();
	});
});

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
