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
import * as path from 'path';
import ChmpxNode from 'chmpx';

//-------------------------------------------------------------------
// Environment
//
const ini_file_path: string = (undefined !== process.env.TESTS_PATH) ? path.join(process.env.TESTS_PATH, "chmpx_server.ini") : "chmpx_server.ini";

//-------------------------------------------------------------------
// Run chmpx nodejs for server process
//
// [NOTE]
// The reason for defining it with let instead of const is to reset
// undefined to force GC to run at the end of the file.
//
let chmpxserverobj: chmpx.ChmpxNode = ChmpxNode();

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
    // Array passed in will be filled by native addon: [compkt, body]
    const outarr: [Buffer?, Buffer?] = [];

	if(!chmpxserverobj.receive((outarr as [Buffer?, Buffer?]), -1)){			// wait
		console.log("[ERROR] failed to receive data on server process.");
		process.exit(1);
	}

	const body = outarr[1];
	if(!body || 0 === body.length){
		continue;
	}

    const receive_str = body.toString();
	console.log("-->Receive = \"%s\"(utf8)",	receive_str);
	console.log("-->Receive = %s(hex)",			(outarr[1] as Buffer).toString('hex'));

	if(receive_str == "BREAK TEST"){
		break;
	}
    const replydata	= Buffer.from('Reply(' + receive_str + ')');
    const result	= chmpxserverobj.reply((outarr[0] as Buffer), replydata);

	console.log("<--Reply = \"%s\" : %s", 		replydata, result);
}

process.exit(0);

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
