---
layout: contents
language: en-us
title: Usage
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: usageja.html
lang_opp_word: To Japanese
prev_url: feature.html
prev_string: Feature
top_url: index.html
top_string: TOP
next_url: build.html
next_string: Build
---

# Usage
Try to check its operation after building CHMPX Node.js addon library.

## 1. Construction of execution environment
First of all, you need to build an execution environment.  
There are two ways to prepare for the environment.
One way is to install the package.
The other way is to build the chmpx nodejs addon library yourself.

### 1.1 Creating an environment using packages
This is a way to create an execution environment using packages.  
The package of chmpx nodejs addon library is in [npm](https://www.npmjs.com/package/chmpx).  

Before installing this package, you will need the CHMPX developer package, so please refer to the [CHMPX documentation](https://chmpx.antpick.ax/).  
There are two ways to install CHMPX.
The first is installing from the package.(Please refer to [CHMPX usage document](https://chmpx.antpick.ax/usage.html).)
The other way is to build CHMPX by yourself.(Please refer to [CHMPX build document](https://chmpx.antpick.ax/build.html).)  
Please create an environment that can use CHMPX in any way.  

After installing the CHMPX in advance, install the npm package of the chmpx nodejs addon library as follows.    
For details of the npm command, please refer to [here](https://docs.npmjs.com/misc/index.html#npm1).
```
$ npm install chmpx
```

### 1.2 Build to create an environment
You can build the chmpx nodejs addon library from the [source code](https://github.com/yahoojapan/chmpx_nodejs).  
See [here](https://nodejs.chmpx.antpick.ax/build.html) for how to clone and build the source code github repository.

## 2. Run CHMPX processes
Run CHMPX processes for server/slave node.  
You can use configuration file(.ini) in `test` directory.  
For details on how to start CHMPX process, please refer [here](https://chmpx.antpick.ax/usage.html).

### 2-1. Run CHMPX server node
```
$ chmpx -conf chmpx_server.ini
```
### 2-2. Run CHMPX slave node
```
$ chmpx -conf chmpx_slave.ini
```

## 3. Examples
The following shows the part that communicates with CHMPX Node.js library on each server node and slave node of CHMPX.

### 3-1. Client running on CHMPX server nodes
```
var chmpxnode      = require('chmpx');
var chmpxserverobj = new chmpxnode();

if(!chmpxserverobj.initializeOnServer('chmpx_server.ini', true)){
	console.log('[ERROR] Failed to inisialize chmpx nodejs on server node, get false from initializeOnServer');
	process.exit(1);
}

while(true){
	var outarr = new Array();

	//
	// Receive message
	//
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
	var replydata = new Buffer('Reply(' + receive_str + ')');

	//
	// Reply message
	//
	result = chmpxserverobj.reply(outarr[0], replydata);

	console.log("<--Reply = \"%s\" : %s", 		replydata, result);
}

delete chmpxserverobj;
chmpxserverobj = null;

process.exit(0);
```

### 3-2. Client running on CHMPX slave nodes
```
var chmpxnode     = require('chmpx');
var chmpxslaveobj = new chmpxnode();

if(!chmpxslaveobj.initializeOnSlave('chmpx_slave.ini', true)){
	console.log('[ERROR] Failed to inisialize chmpx nodejs on slave node, get false from InitializeOnSlave');
	process.exit(1);
}

//
// Open msgid for slave process
//
var msgid  = chmpxslaveobj.open();

//
// Send one message
//
var result = chmpxslaveobj.send(msgid, 'TEST MESSAGE');
if(-1 == result){
	console.log('[ERROR] - [msgid:%s][data:%s] Result : false', msgid.toString('hex'), data.toString('hex'));
	return false;
}
console.log('<--- %s(hex) : %s', msgid.toString('hex'), result);

//
// Receive reply message
//
var bufarr = new Array();
result = chmpxslaveobj.receive(msgid, bufarr, 1000);

console.log('---> Receive(%s(hex)) : %s', msgid.toString('hex'), result);
console.log('     buf array length = ' + bufarr.length);

//
// Close msgid
//
if(false === chmpxslaveobj.close(msgid)){
	console.log('[ERROR] Close(msgid): failed to close msgid.');
	process.exit(1);
}

delete chmpxslaveobj;
chmpxslaveobj = null;

process.exit(0);
```

## 4. Importing and Executing
First, import the CHMPX Node.js addon library with `require` to read the library in the JavaScript language.
After that, you can call the class, function, and method provided by CHMPX Node.js addon library.
Please implement these depending on your environment and language(TypeScript etc.).

## 5. Other test
CHMPX Node.js addon library provides unit testing using [Mocha](https://github.com/mochajs/mocha) and [Chai](https://github.com/chaijs/chai).
You can test CHMPX Node.js addon library built by using the [npm](https://www.npmjs.com/get-npm) command as shown below.
```
$ npm run test
```
