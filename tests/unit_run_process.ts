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
 * CREATE:   Thu Nov 8 2018
 * REVISION:
 *
 */

//
// Common Start/Stop sub-processes for before/after in mocha
//
import { execSync } from 'child_process';		// For before section to launching sub processes

// [NOTE]
// If this file has included the @types/mocha, we should use the
// "Mocha.Context" type, but here we will only deal with the timeout
// attribute of Mocha.Context and will not be aware of Mocha.Context.
// Therefore, we will use a type declaration for only the timeout
// attribute.
//
export type ParentWithTimeout = {
	timeout: (ms?: number) => number;
};

//
// Before : Start sub processes(server chmpx/slave chmpx/server node) for slave test
//
export const startServer = (parentobj: ParentWithTimeout, testdir: string): void =>
{
	console.log('        START SUB PROCESSES FOR TESTING SLAVE:');

	//
	// Change timeout for running sub-processes
	//
	const orgTimeout = parentobj.timeout(30000);

	//
	// Run server chmpx for server node
	//
	let	result = execSync(testdir + '/run_process_helper.sh start_chmpx_server');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));

	//
	// Run slave chmpx for slave node
	//
	result = execSync(testdir + '/run_process_helper.sh start_chmpx_slave');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));

	//
	// Run server node process
	//
	result = execSync(testdir + '/run_process_helper.sh start_node_server');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

//
// Before : Start sub processes(server chmpx/slave chmpx) for server test
//
export const startSlaveChmpx = (parentobj: ParentWithTimeout, testdir: string): void =>
{
	console.log('        START SUB PROCESSES(CHMPX) FOR TESTING SERVER:');

	//
	// Change timeout for running sub-processes
	//
	const orgTimeout = parentobj.timeout(30000);

	//
	// Run server chmpx for server node
	//
	let	result = execSync(testdir + '/run_process_helper.sh start_chmpx_server');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));

	//
	// Run slave chmpx for slave node
	//
	result = execSync(testdir + '/run_process_helper.sh start_chmpx_slave');
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
export const startSlaveNode = (parentobj: ParentWithTimeout, testdir: string): void =>
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
	const result = execSync(testdir + '/run_process_helper.sh start_node_slave');
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
export const stopProcs = (parentobj: ParentWithTimeout, testdir: string): void =>
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
	const	result = execSync(testdir + '/run_process_helper.sh stop_all');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
