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
 * CREATE:   Mon Oct 31 2016
 * REVISION:
 *
 */

//-------------------------------------------------------------------
// Requires
//
var chmpxnode = require('chmpx');

//-------------------------------------------------------------------
// Environment
//
var	ini_file_path = "chmpx_server.ini";
if(process.env.TESTDIR_PATH != undefined){
	ini_file_path = process.env.TESTDIR_PATH + "/chmpx_server.ini";
}

//-------------------------------------------------------------------
// Run chmpx nodejs for server process
//
var chmpxserverobj = new chmpxnode();

console.log('* TEST : class object type         = %s', chmpxserverobj);
console.log('* TEST : IsChmpxExit(expect false) = %s', chmpxserverobj.isChmpxExit());

if(!chmpxserverobj.initializeOnServer(ini_file_path, true)){
	console.log('[ERROR] Failed to inisialize chmpx nodejs on server node, get false from initializeOnServer');
	process.exit(1);
}

//
// Loop for receiving data on server process
//
console.log('* TEST : Loop for recieving data');

while(true){
	var outarr = new Array();

	if(!chmpxserverobj.receive(outarr, -1)){								// wait
		console.log("[ERROR] failed to receive data on server process.");
		process.exit(1);
	}

	if(0 == outarr[1].length){
		continue;
	}

	var receive_str = outarr[1].toString();
	console.log("-->Receive = \"%s\"(utf8)",	receive_str);
	console.log("-->Receive = %s(hex)",			outarr[1].toString('hex'));

	if(receive_str == "BREAK TEST"){
		break;
	}
	var replydata = Buffer.from('Reply(' + receive_str + ')');

	result = chmpxserverobj.reply(outarr[0], replydata);

	console.log("<--Reply = \"%s\" : %s", 		replydata, result);
}

delete chmpxserverobj;
chmpxserverobj = null;

process.exit(0);

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
