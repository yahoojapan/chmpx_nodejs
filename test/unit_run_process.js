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
 * CREATE:   Thu Nov 8 2018
 * REVISION:
 *
 */

'use strict';

//
// Common Start/Stop sub-processes for before/after in mocha
//
var	execSync = require('child_process').execSync;			// For before section to launching sub processes

//
// Before : Start sub processes(server chmpx/slave chmpx/server node) for slave test
//
exports.startServer = function(parentobj, testdir)
{
	console.log('        START SUB PROCESSES FOR TESTING SLAVE:');

	//
	// Change timeout for running sub-processes
	//
	var	orgTimeout = parentobj.timeout(30000);

	//
	// Run server chmpx for server node
	//
	var	result = execSync(testdir + '/run_process_helper.sh start_chmpx_server');
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
exports.startSlaveChmpx = function(parentobj, testdir)
{
	console.log('        START SUB PROCESSES(CHMPX) FOR TESTING SERVER:');

	//
	// Change timeout for running sub-processes
	//
	var	orgTimeout = parentobj.timeout(30000);

	//
	// Run server chmpx for server node
	//
	var	result = execSync(testdir + '/run_process_helper.sh start_chmpx_server');
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
exports.startSlaveNode = function(parentobj, testdir)
{
	console.log('');
	console.log('        START SUB PROCESSES(SLAVE NODE) FOR TESTING SERVER:');

	//
	// Change timeout for running sub-processes
	//
	var	orgTimeout = parentobj.timeout(30000);

	//
	// Run slave node process
	//
	var result = execSync(testdir + '/run_process_helper.sh start_node_slave');
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
exports.stop = function(parentobj, testdir)
{
	console.log('');
	console.log('        STOP ALL SUB PROCESSES:');

	//
	// Change timeout for running sub-processes
	//
	var	orgTimeout = parentobj.timeout(30000);

	//
	// Stop all sub processes
	//
	var	result = execSync(testdir + '/run_process_helper.sh stop_all');
	console.log('          -> ' + String(result).replace(/\r?\n$/g, ''));
	console.log('');

	//
	// Reset timeout
	//
	parentobj.timeout(orgTimeout);
};

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
