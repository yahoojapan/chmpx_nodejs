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
 * CREATE:   Mon Oct 31 2016
 * REVISION:
 *
 */

//-------------------------------------------------------------------
// Requires
//
var chmpxnode = require('chmpx');

//-------------------------------------------------------------------
// Common function
//
// [NOTE]
// This sleep is high load avarage, but this script is only test.
//
function sleep(milliseconds)
{
	var start = new Date().getTime();
	while(true){
		if ((new Date().getTime() - start) > milliseconds){
			break;
		}
	}
}

//
// Send and Recieve
//
function sendReceive(msgid, data, timeout_ms, bcast)
{
	var timeout_val	= (0 != timeout_ms)	? timeout_ms	: 1000;
	var method		= (true === bcast)	? 'Broadcast'	: 'Send';
	var result;

	if(true === bcast){
		result = chmpxslaveobj.broadcast(msgid, data);
	}else{
		result = chmpxslaveobj.send(msgid, data);
	}
	console.log('<--- %s(%s(hex)) : %s', method, msgid.toString('hex'), result);

	if(-1 == result){
		console.log('[ERROR] %s Receive : [msgid:%s][data:%s][timeout:%dms][%s], Result : false', method, msgid.toString('hex'), data.toString('hex'), timeout_ms, bcast);
		return false;
	}

	var bufarr = new Array();
	result = chmpxslaveobj.receive(msgid, bufarr, timeout_val);

	console.log('---> Receive(%s(hex)) : %s', msgid.toString('hex'), result);
	console.log('     buf array length = ' + bufarr.length);

	if(2 <= bufarr.length){
		console.log('     buf[0] = %s(hex)',		bufarr[0].toString('hex'));
		console.log('     buf[1] = \"%s\"(utf8)',	bufarr[1].toString());
		console.log('     buf[1] = %s(hex)',		bufarr[1].toString('hex'));
	}else{
		return false;
	}
	console.log();
	return true;
}

//-------------------------------------------------------------------
// Run chmpx nodejs for slave process
//
var chmpxslaveobj = new chmpxnode();

if(!chmpxslaveobj.initializeOnSlave('chmpx_slave.ini', true)){
	console.log('[ERROR] Failed to inisialize chmpx nodejs on slave node, get false from InitializeOnSlave');
	process.exit(1);
}

//
// Open msgid for slave process
//
var msgid1 = chmpxslaveobj.open();
var msgid2 = chmpxslaveobj.open();
console.log('-> Open(msgid1): %s', msgid1.toString('hex'));
console.log('-> Open(msgid2): %s', msgid2.toString('hex'));

sendReceive(msgid2, Buffer.from('Broadcast message.'), 1000, true);				// normal(broadcast)
sendReceive(msgid2, Buffer.from('センドレシーブ'), 1000, false);				// japanese(utf-8)
sendReceive(msgid2, Buffer.from([0xE2,0x87,0x92,0xE3,0x8C,0xAB]), 1000, false);	// japanese(utf-8: special words)
sendReceive(msgid1, Buffer.from('send receive.'), 1000, false);					// normal(send)

if(false === chmpxslaveobj.close(msgid1)){
	console.log('[ERROR] Close(msgid1): failed to close msgid.');
	process.exit(1);
}

var result = sendReceive(msgid1, Buffer.from('msgid1: after Close()'), 1000, false);
console.log('<- SendAfterClose(%s(hex)) : %s', msgid1.toString('hex'), result);

//
// Stop receiving server process
//
sendReceive(msgid2, Buffer.from('BREAK TEST'), 1000, false);			// for stop server process

delete chmpxslaveobj;
chmpxslaveobj = null;

process.exit(0);

/*
 * VIM modelines
 *
 * vim:set ts=4 fenc=utf-8:
 */
