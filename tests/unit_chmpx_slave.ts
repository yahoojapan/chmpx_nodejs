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

import	path				from "path";
declare const __dirname: string | undefined;
const _fallbackdir: string	= path.join(process.cwd(), "tests");
const testsdir: string		= path.resolve(process.env.TESTS_PATH ?? (typeof __dirname !== "undefined" ? __dirname : _fallbackdir));
const run_proc_opt: string	= (process.env.SCRIPT_TYPE?.trim().toLowerCase() === 'cjs') ? '--commonjs' : '';

import	* as _chmpx			from 'chmpx';
const	chmpxnode: any		= (_chmpx as any).default ?? _chmpx;

// [NOTE] About chai
// In NodeJS 20, this unit test code will be converted to CommonJS by
// tsc and then executed.
// However, in Alpine's NodeJS 20, chai only supports ESM (import),
// resulting in an error.(ESM-only)
// For this reason, we will make sure that only chai calls the native
// import.
//
// If this issue did not exist (NodeJS 20 is no longer supported due
// to its EOL), the code could be simplified as follows:
//		----------------------------------
//		import * as chai from 'chai';
//		const { assert, expect } = chai;
//		before(function(){
//		});
//		----------------------------------
//
let	assert: any;	// assert.chai
let	expect: any;	// expect.chai

//--------------------------------------------------------------
// Common function
//--------------------------------------------------------------
//
// Helper function for calling native dynamic import function
//
// [NOTE]
// This is chai's ESM-only problem.
//
function nativeDynamicImport(specifier: string): Promise<any>
{
	// [NOTE]
	// When using "new Function()", tsc won't convert this contents,
	// which means that Node's import() will be called at runtime
	// even after converting to CommonJS.
	//
	return (new Function('s', 'return import(s)'))(specifier);
}

//--------------------------------------------------------------
// Before in global section
//--------------------------------------------------------------
// [NOTE]
// For chai's ESM-only problem
//
// When importing(requiring) chai in NodeJS 20, native import will
// be attempted even in CommonJS.
// This allows you to import chai, which is ESM-only. If the import
// fails, the require will be retried.
//
before(async function()
{
	// Try import()
	try{
		const	chaiModule	= await nativeDynamicImport('chai');
		const	chai		= (chaiModule && (chaiModule as any).default) ? (chaiModule as any).default : chaiModule;
		assert	= chai.assert;
		expect	= chai.expect;
	}catch(error: any){
		// Retry with require()
		try{
			// eslint-disable-next-line @typescript-eslint/no-var-requires
			const	chai = require('chai');
			assert	= chai.assert;
			expect	= chai.expect;
		}catch(error2: any){
			throw new Error('Failed to load chai via import() and require(): ' + JSON.stringify(error2));
		}
	}
});

//--------------------------------------------------------------
// After in global section
//--------------------------------------------------------------
after(function(){
	// Nothing to do
});

//--------------------------------------------------------------
// BeforeEach in global section
//--------------------------------------------------------------
beforeEach(function(){
	// Nothing to do
});

//--------------------------------------------------------------
// AfterEach in global section
//--------------------------------------------------------------
afterEach(function(){
	// Nothing to do
});

//--------------------------------------------------------------
// Utility: Launch Processes
//--------------------------------------------------------------
// [NOTE]
// Previously, these utility functions were in a separate file,
// but now we'll write them directly in this test file.
// This is a last resort to avoid the error that is output when
// executing import(require).
//
import { execSync } from 'child_process';

// [NOTE]
// If this file has included the @types/mocha, we should use the
// "Mocha.Context" type, but here we will only deal with the timeout
// attribute of Mocha.Context and will not be aware of Mocha.Context.
// Therefore, we will use a type declaration for only the timeout
// attribute.
//
type ParentWithTimeout = {
	timeout: (ms?: number) => number;
};

//
// Before : Start sub processes(server chmpx/slave chmpx/server node) for slave test
//
const startServer = (parentobj: ParentWithTimeout, testsdir: string): void =>
{
	console.log('        START SUB PROCESSES FOR TESTING SLAVE:');

	//
	// Change timeout for running sub-processes
	//
	const orgTimeout = parentobj.timeout(30000);

	//
	// Run server chmpx for server node
	//
	let	result = execSync(testsdir + '/run_process_helper.sh ' + run_proc_opt + ' start_chmpx_server');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));

	//
	// Run slave chmpx for slave node
	//
	result = execSync(testsdir + '/run_process_helper.sh ' + run_proc_opt + ' start_chmpx_slave');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));

	//
	// Run server node process
	//
	result = execSync(testsdir + '/run_process_helper.sh ' + run_proc_opt + ' start_node_server');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

//
// After : Stop all sub processes
//
const stopProcs = (parentobj: ParentWithTimeout, testsdir: string): void =>
{
	console.log('');
	console.log('        STOP ALL SUB PROCESSES:');

	//
	// Change timeout for running sub-processes
	//
	const orgTimeout = parentobj.timeout(30000);

	//
	// Stop all sub processes
	//
	const	result = execSync(testsdir + '/run_process_helper.sh ' + run_proc_opt + ' stop_all');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

//--------------------------------------------------------------
// Main describe section
//--------------------------------------------------------------
describe('CHMPX SLAVE', function(){
	//
	// Global
	//
	let chmpxslaveobj: any		= null;
	let	msgid1: Buffer | null	= null;
	let	msgid2: Buffer | null	= null;

	//
	// Before in describe section
	//
	before(function(done){
		startServer(this as any, testsdir);
		chmpxslaveobj = new chmpxnode();
		done();
	});

	//
	// After in describe section
	//
	after(function(done){
		stopProcs(this as any, testsdir);
		done();
	});

	//-------------------------------------------------------------------
	// Test Slave side
	//-------------------------------------------------------------------
	//
	// ChmpxNode::initializeOnServer() - No Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - No Callback', function(done){
		// No initializing callback
		expect(typeof chmpxslaveobj).to.equal('object');
		expect(chmpxslaveobj.isChmpxExit()).to.be.a('boolean').to.be.false;
		expect(chmpxslaveobj.initializeOnSlave(testsdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;

		done();
	});

	//
	// ChmpxNode::initializeOnSlave() - on Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - on Callback', function(done){
		// Registered initializing callback
		expect(chmpxslaveobj.on('initializeOnSlave', function(error: any)
		{
			expect(error).to.be.null;
			chmpxslaveobj.off('initializeOnSlave');

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxslaveobj.initializeOnSlave(testsdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnSlave() - onInitializeOnSever Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - onInitializeOnSever Callback', function(done){
		// Registered initializing callback
		expect(chmpxslaveobj.onInitializeOnSlave(function(error: any)
		{
			expect(error).to.be.null;
			chmpxslaveobj.offInitializeOnSlave();

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxslaveobj.initializeOnSlave(testsdir + '/chmpx_slave.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnSlave() - inline Callback
	//
	it('Slave test - ChmpxNode::initializeOnSlave() - inline Callback', function(done){
		// Inline initializing Callback
		expect(chmpxslaveobj.initializeOnSlave(testsdir + '/chmpx_slave.ini', true, function(error: any)
		{
			expect(error).to.be.null;

			done();
		})).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::open(), close() - on Callback
	//
	it('Slave test - ChmpxNode::open(), close() - on Callback', function(done){
		expect(chmpxslaveobj.on('open', function(error: any, msgid: Buffer)
		{
			expect(error).to.be.null;

			// close test
			expect(chmpxslaveobj.on('close', function(error: any)
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
	it('Slave test - ChmpxNode::open(), close() - onOpen Callback', function(done){
		expect(chmpxslaveobj.onOpen(function(error: any, msgid: Buffer)
		{
			expect(error).to.be.null;

			// close test
			expect(chmpxslaveobj.onClose(function(error: any)
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
	it('Slave test - ChmpxNode::open(), close() - inline Callback', function(done){
		expect(chmpxslaveobj.open(function(error: any, msgid: Buffer)
		{
			expect(error).to.be.null;

			// close
			expect(chmpxslaveobj.close(msgid, function(error: any)
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
	it('Slave test - ChmpxNode::open() - No Callback', function(done){
		msgid1 = chmpxslaveobj.open();
		msgid2 = chmpxslaveobj.open();
		expect(msgid1).to.not.be.null;
		expect(msgid2).to.not.be.null;
		done();
	});

	//
	// ChmpxNode::send(), receive() - No Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - No Callback', function(done){
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'))).to.not.equal(-1);

		// receive
		const buffarr: Buffer[] = [];
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);

		done();
	});

	//
	// ChmpxNode::send(), receive() - on Callback
	//
	it('Slave test - ChmpxNode::send(), receive() - on Callback', function(done){
		expect(msgid1).to.not.be.null;

		// set for send
		expect(chmpxslaveobj.on('send', function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// set for receive
			expect(chmpxslaveobj.on('receive', function(error: any, compkt: Buffer, data: Buffer)
			{
				expect(error).to.be.null;
				expect(data).to.not.be.null;
				expect(data.toString()).to.equal('Reply(send receive.)');

				// unset for receive
				chmpxslaveobj.off('receive');

				done();
			})).to.be.a('boolean').to.be.true;

			// receive
			const buffarr: Buffer[] = [];
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
	it('Slave test - ChmpxNode::send(), receive() - onSend/onReceive Callback', function(done){
		expect(msgid1).to.not.be.null;

		// set for send
		expect(chmpxslaveobj.onSend(function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// set for receive
			expect(chmpxslaveobj.onReceive(function(error: any, compkt: Buffer, data: Buffer)
			{
				expect(error).to.be.null;
				expect(data).to.not.be.null;
				expect(data.toString()).to.equal('Reply(send receive.)');

				// unset for receive
				chmpxslaveobj.off('receive');

				done();
			})).to.be.a('boolean').to.be.true;

			// receive
			const buffarr: Buffer[] = [];
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
	it('Slave test - ChmpxNode::send(), receive() - inline Callback', function(done){
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('send receive.'), function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// receive
			expect(chmpxslaveobj.receive(msgid1, 1000, function(error: any, compkt: Buffer, data: Buffer)
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
	it('Slave test - ChmpxNode::broadcast(), receive() - No Callback', function(done){
		expect(msgid1).to.not.be.null;

		// broadcast
		let	recievercnt: number = chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'));
		expect(recievercnt).to.not.equal(-1);

		// receive
		for(; 0 < recievercnt; --recievercnt){
			const buffarr: Buffer[] = [];
			expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
			expect(buffarr.length).to.equal(2);
		}
		done();
	});

	//
	// ChmpxNode::broadcast(), receive() - on Callback
	//
	it('Slave test - ChmpxNode::broadcast(), receive() - on Callback', function(done){
		expect(msgid1).to.not.be.null;

		// set for broadcast
		expect(chmpxslaveobj.on('broadcast', function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				const buffarr: Buffer[] = [];
				expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;
			}

			// unset for receive
			chmpxslaveobj.off('receive');

			// unset for broadcast
			chmpxslaveobj.off('broadcast');
		})).to.be.a('boolean').to.be.true;

		// set for receive
		expect(chmpxslaveobj.on('receive', function(error: any, compkt: Buffer, data: Buffer)
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
	it('Slave test - ChmpxNode::broadcast(), receive() - onBroadcast/onReceive Callback', function(done){
		expect(msgid1).to.not.be.null;

		// set for broadcast
		expect(chmpxslaveobj.onBroadcast(function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				const buffarr: Buffer[] = [];
				expect(chmpxslaveobj.receive(msgid1, 1000)).to.be.a('boolean').to.be.true;
			}

			// unset for receive
			chmpxslaveobj.off('receive');

			// unset for broadcast
			chmpxslaveobj.off('broadcast');
		})).to.be.a('boolean').to.be.true;

		// set for receive
		expect(chmpxslaveobj.onReceive(function(error: any, compkt: Buffer, data: Buffer)
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
	it('Slave test - ChmpxNode::broadcast(), receive() - inline Callback', function(done){
		expect(msgid1).to.not.be.null;

		// broadcast
		expect(chmpxslaveobj.broadcast(msgid1, Buffer.from('broadcast receive.'), function(error: any, receivecount: number)
		{
			expect(error).to.be.null;

			// receive
			for(; 0 < receivecount; --receivecount){
				expect(chmpxslaveobj.receive(msgid1, 1000, function(error: any, compkt: Buffer, data: Buffer)
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
	it('Slave test - ChmpxNode::send() - japanese', function(done){
		expect(msgid1).to.not.be.null;

		// send
		expect(chmpxslaveobj.send(msgid1, Buffer.from('センドレシーブ'))).to.not.equal(-1);

		// receive
		const buffarr: Buffer[] = [];
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);
		expect(buffarr[1].toString()).to.equal('Reply(センドレシーブ)');
		done();
	});

	//
	// ChmpxNode::send() - special japanese
	//
	it('Slave test - ChmpxNode::send() - special japanese', function(done){
		expect(msgid1).to.not.be.null;

		// send
		const target_str = Buffer.from([0xE2, 0x87, 0x92, 0xE3, 0x8C, 0xAB]);
		expect(chmpxslaveobj.send(msgid1, target_str)).to.not.equal(-1);

		// receive
		const buffarr: Buffer[] = [];
		expect(chmpxslaveobj.receive(msgid1, buffarr, 1000)).to.be.a('boolean').to.be.true;
		expect(buffarr.length).to.equal(2);

		const receive_str = 'Reply(' + target_str + ')';
		expect(buffarr[1].toString()).to.equal(receive_str);

		done();
	});

	//
	// ChmpxNode::send() - error after closing msgid
	//
	it('Slave test - ChmpxNode::send() - error after closing msgid', function(done){
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
	it('Slave test - ChmpxNode::close() - normal', function(done){
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
