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
// Before : Start sub processes(server chmpx/slave chmpx) for server test
//
const startSlaveChmpx = (parentobj: ParentWithTimeout, testsdir: string): void =>
{
	console.log('        START SUB PROCESSES(CHMPX) FOR TESTING SERVER:');

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
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

//
// Before : Start sub processes(slave node) for server test
//
const startSlaveNode = (parentobj: ParentWithTimeout, testsdir: string): void =>
{
	console.log('');
	console.log('        START SUB PROCESSES(SLAVE NODE) FOR TESTING SERVER:');

	//
	// Change timeout for running sub-processes
	//
	const orgTimeout = parentobj.timeout(30000);

	//
	// Run slave node process
	//
	const result = execSync(testsdir + '/run_process_helper.sh ' + run_proc_opt + ' start_node_slave');
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
describe('CHMPX SERVER', function(){
	//
	// Global
	//
	let chmpxserverobj: any	= null;

	//
	// Before in describe section
	//
	before(function(done){
		startSlaveChmpx(this as any, testsdir);
		chmpxserverobj = new chmpxnode();
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
	// Test Server side
	//-------------------------------------------------------------------
	//
	// ChmpxNode::initializeOnServer() - No Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - No Callback', function(done){
		// No initializing callback
		expect(typeof chmpxserverobj).to.equal('object');
		expect(chmpxserverobj.isChmpxExit()).to.be.a('boolean').to.be.false;
		expect(chmpxserverobj.initializeOnServer(testsdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;

		done();
	});

	//
	// ChmpxNode::initializeOnServer() - on Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - on Callback', function(done){
		// Registered initializing callback
		expect(chmpxserverobj.on('initializeOnServer', function(error: any)
		{
			expect(error).to.be.null;
			chmpxserverobj.off('initializeOnServer');

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxserverobj.initializeOnServer(testsdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnServer() - onInitializeOnSever Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - onInitializeOnSever Callback', function(done){
		// Registered initializing callback
		expect(chmpxserverobj.onInitializeOnServer(function(error: any)
		{
			expect(error).to.be.null;
			chmpxserverobj.offInitializeOnServer();

			done();
		})).to.be.a('boolean').to.be.true;

		expect(chmpxserverobj.initializeOnServer(testsdir + '/chmpx_server.ini', true)).to.be.a('boolean').to.be.true;
	});

	//
	// ChmpxNode::initializeOnServer() - inline Callback
	//
	it('Server test - ChmpxNode::initializeOnServer() - inline Callback', function(done){
		// Inline initializing Callback
		expect(chmpxserverobj.initializeOnServer(testsdir + '/chmpx_server.ini', true, function(error: any)
		{
			expect(error).to.be.null;

			done();
		})).to.be.a('boolean').to.be.true;
	});

	//
	// Run processes(node chmpx slave)
	//
	it('Server test - RUN PROCESSES(TEST SLAVE NODE)', function(done){
		startSlaveNode(this, testsdir);
		done();
	});

	//
	// ChmpxNode::receive() - Broadcast
	//
	it('Server test - ChmpxNode::receive() - Broadcast', function(done){
		while(true){
			const outarr: Buffer[] = [];

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				const receive_str = outarr[1].toString();
				expect(receive_str).to.equal('Broadcast message.');

				const replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - japanese(utf-8)
	//
	it('Server test - ChmpxNode::receive() - japanese(utf-8)', function(done){
		while(true){
			const outarr: Buffer[] = [];

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				const receive_str = outarr[1].toString();
				expect(receive_str).to.equal('センドレシーブ');

				const replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - japanese(utf-8: special words)
	//
	it('Server test - ChmpxNode::receive() - japanese(utf-8: special words)', function(done){
		while(true){
			const outarr: Buffer[] = [];

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				const target_str = Buffer.from([0xE2, 0x87, 0x92, 0xE3, 0x8C, 0xAB]);
				expect(Buffer.compare(outarr[1], target_str)).to.equal(0);

				const replydata = Buffer.from('Reply(' + outarr[1].toString() + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - normal
	//
	it('Server test - ChmpxNode::receive() - normal', function(done){
		while(true){
			const outarr: Buffer[] = [];

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				const receive_str = outarr[1].toString();
				expect(receive_str).to.equal('send receive.');

				const replydata = Buffer.from('Reply(' + receive_str + ')');
				expect(chmpxserverobj.reply(outarr[0], replydata)).to.be.a('boolean').to.be.true;

				break;
			}
		}
		done();
	});

	//
	// ChmpxNode::Receive() - break
	//
	it('Server test - ChmpxNode::receive() - break', function(done){
		while(true){
			const outarr: Buffer[] = [];

			expect(chmpxserverobj.receive(outarr, 2000)).to.be.a('boolean').to.be.true;
			if(0 != outarr[1].length){
				const receive_str = outarr[1].toString();
				expect(receive_str).to.equal('BREAK TEST');

				break;
			}
		}
		done();
	});

	//
	// Read rest messages
	//
	it('Server test - Delete ChmpxNode object', function(done){
		// get rest data if exists
		while(true){
			const outarr: Buffer[] = [];

			if(!chmpxserverobj.receive(outarr, 500) || 0 == outarr[1].length){
				break;
			}
		}
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
