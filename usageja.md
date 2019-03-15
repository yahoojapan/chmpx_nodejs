---
layout: contents
language: ja
title: Usage
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: usage.html
lang_opp_word: To English
prev_url: featureja.html
prev_string: Feature
top_url: indexja.html
top_string: TOP
next_url: buildja.html
next_string: Build
---

# 使い方
CHMPX Node.jsをビルドした後で、動作確認をしてみます。

## 1. 実行環境の構築
まず、実行環境を構築します。  
構築は、パッケージから構築する方法と、chmpx nodejs addonライブラリをビルドして利用する方法があります。

### 1.1 パッケージを利用して環境を構築
パッケージを利用して実行環境を構築する方法を説明します。  
chmpx nodejs addonライブラリのパッケージは、[npm](https://www.npmjs.com/package/chmpx)にあります。  

このパッケージをインストールする前に、CHMPXの開発者パッケージが必要となりますので、CHMPXの[ドキュメント](https://chmpx.antpick.ax/indexja.html)を参照してください。  
CHMPXをインストールする方法も、パッケージからのインストールと、CHMPXを自身でビルドする方法がありますので、[使い方](https://chmpx.antpick.ax/usageja.html)もしくは[ビルド](https://chmpx.antpick.ax/buildja.html)のドキュメントを参照してください。  

事前にCHMPXをインストールした後、chmpx nodejs addonライブラリのnpmパッケージは、以下のようにインストールします。  
npmコマンドの詳細については[こちら](https://docs.npmjs.com/misc/index.html#npm1)を参照してください。  
```
$ npm install chmpx
```
### 1.2 ビルドして環境を構築
ソースコードからchmpx nodejs addonライブラリをビルドすることができます。  
ソースコードのgithubリポジトリをcloneし、ビルドする方法は[こちら](https://nodejs.chmpx.antpick.ax/buildja.html)を参照してください。

## 2. CHMPXプロセス起動
ここでは、CHMPXプロセスの起動を簡単に説明します。  
CHMPXプログラムの起動に必要となる設定ファイルは、`test`ディレクトリにあるファイル（*.ini）を使うことができます。  
CHMPXプロセスの起動方法の詳細については、[こちら](https://chmpx.antpick.ax/usageja.html)を参照してください。

### 2-1. CHMPXサーバノード起動
```
$ chmpx -conf chmpx_server.ini
```
### 2-2. CHMPXスレーブノード起動
```
$ chmpx -conf chmpx_slave.ini
```

## 3. サンプル
サンプルとして、CHMPXのサーバーノード、スレーブノードのそれぞれでCHMPX Node.jsライブラリを使って通信する部分を以下に示します。

### 3-1. サーバーノード上で動作するクライアント
```
var chmpxnode      = require('chmpx');
var chmpxserverobj = new chmpxnode();

if(!chmpxserverobj.initializeOnServer('chmpx_server.ini', true)){
	console.log('[ERROR] Failed to initialize chmpx nodejs on server node, get false from initializeOnServer');
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

### 3-2. スレーブノード上で動作するクライアント
```
var chmpxnode     = require('chmpx');
var chmpxslaveobj = new chmpxnode();

if(!chmpxslaveobj.initializeOnSlave('chmpx_slave.ini', true)){
	console.log('[ERROR] Failed to initialize chmpx nodejs on slave node, get false from InitializeOnSlave');
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
var buffarr = new Array();
result = chmpxslaveobj.receive(msgid, buffarr, 1000);

console.log('---> Receive(%s(hex)) : %s', msgid.toString('hex'), result);
console.log('     buf array length = ' + buffarr.length);

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

## 4. ロード・実行
基本として、JavaScript言語でライブラリを読み込むための`require`でCHMPX Node.js アドオンライブラリを読み込みます。  
その後は、CHMPX Node.js アドオンライブラリが提供するクラス・関数・メソッドを呼び出してください。  
具体的には、環境や言語（TypeScriptなど）に応じて利用してください。

## 5. その他のテスト  
CHMPX Node.jsでは、[Mocha](https://github.com/mochajs/mocha)と[Chai](https://github.com/chaijs/chai)を使ったテストを実行できます。  
以下のように[npm](https://www.npmjs.com/get-npm)コマンドを使い、作成したCHMPX Node.jsをテストすることができます。  
```
$ npm run test
```
