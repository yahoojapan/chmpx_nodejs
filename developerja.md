---
layout: contents
language: ja
title: Developer
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: developer.html
lang_opp_word: To English
prev_url: buildja.html
prev_string: Build
top_url: indexja.html
top_string: TOP
next_url: environmentsja.html
next_string: Environments
---

<!-- -----------------------------------------------------------　-->
# 開発者向け

## [共通](#COMMON)
[同期と非同期](#ASYNCHRONOUS)  
[提供されるクラス](#ABOUTCLASS)  

## [ChmpxNodeクラス](#CHMPXNODECLASS)
[ChmpxNode::InitializeOnServer()](#CHMPXNODE-INITIALIZEONSERVER)  
[ChmpxNode::InitializeOnSlave()](#CHMPXNODE-INITIALIZEONSLAVE)  
[ChmpxNode::Open()](#CHMPXNODE-OPEN)  
[ChmpxNode::Close()](#CHMPXNODE-CLOSE)  
[ChmpxNode::Send()](#CHMPXNODE-SEND)  
[ChmpxNode::Broadcast()](#CHMPXNODE-BROADCAST)  
[ChmpxNode::Receive() - スレーブノード用](#CHMPXNODE-RECEIVE-SLAVE)  
[ChmpxNode::Receive() - サーバーノード用](#CHMPXNODE-RECEIVE-SERVER)  
[ChmpxNode::Reply()](#CHMPXNODE-REPLY)  
[ChmpxNode::IsChmpxExit()](#CHMPXNODE-ISCHMPXEXIT)  

<!-- -----------------------------------------------------------　-->
***

## <a name="COMMON"> 共通
### <a name="ASYNCHRONOUS"> 同期と非同期
CHMPX Node.js アドオンライブラリのクラスのメソッドは、同期処理とCallback関数を指定できる非同期処理をサポートしています。  
非同期処理をサポートしているメソッドは、callback関数の引数を受け取ることができます。  
また、非同期処理として**on**や**onXXXXX**でイベントハンドラーを指定することもできます。  
callback関数もしくはイベントハンドラーの指定をすることで非同期処理を行うことができます。  

callback関数の引数を指定しない場合やイベントハンドラーの指定を指定しない場合、各々のメソッドは同期処理として動作します。

### <a name="ABOUTCLASS"> 提供されるクラス
CHMPX Node.js アドオンライブラリは、**ChmpxNode**クラスを提供します。  
この**ChmpxNode**クラスをサーバーノードのクライアントとして初期化し、サーバーノード側クライアントとして通信を行います。  
また、スレーブノードのクライアントとして初期化し、スレーブノード側クライアントとして通信できます。

<!-- -----------------------------------------------------------　-->
***

## <a name="CHMPXNODECLASS"> ChmpxNodeクラス
CHMPX Node.js アドオンライブラリの提供するメインクラスです。  
このクラスを使い、サーバーノード側クライアントおよびスレーブノード側クライアントとして通信ができます。

クラスを生成するには以下のように指定します。
- サーバーノード側のクライアント  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```
- スレーブノード側のクライアント  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true)
  ```

以下に、ChmpxNodeクラスのメソッドとその説明をします。

### <a name="CHMPXNODE-INITIALIZEONSERVER"> ChmpxNode::InitializeOnServer()
CHMPXサーバーノード側に接続するためにChmpxNodeオブジェクトを初期化します。

#### 書式
```
bool InitializeOnServer(String   filepath,
                        bool     is_auto_rejoin = false,
                        Callback cbfunc = null
)
```

#### 引数
- filepath  
  CHMPXサーバーノードプロセスを起動したときの設定ファイル（iniファイルなど）と同じファイルを指定します。
- is_auto_rejoin  
  trueを指定した場合、CHMPXサーバーノードプロセスが起動するまでブロックします。  
  falseを指定した場合、CHMPXサーバーノードプロセスが起動していないときにはエラーとなります。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true, function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('initializeOnServer', Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.on('initializeOnServer', function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```
- onInitializeOnServer(Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.onInitializeOnServer(function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```

#### 注意
メソッド引数is_auto_rejoinをfalseで呼び出した場合、CHMPXサーバーノードプロセスが起動していないときにはすぐにエラーとして本メソッド呼び出しは完了します。  
is_auto_rejoinをtrueで呼び出した場合、CHMPXサーバーノードプロセスが起動していないときには、起動するまで本メソッドはブロックされます。  
CHMPXプロセスがダウンした場合に再起動まで待った後、処理を行うようにするには、この引数をtrueとすることで、クライアントプログラムを簡単に実装できます。

### <a name="CHMPXNODE-INITIALIZEONSLAVE"> ChmpxNode::InitializeOnSlave()
CHMPXスレーブノード側に接続するためにChmpxNodeオブジェクトを初期化します。

#### 書式
```
bool InitializeOnSlave(String   filepath,
                       bool     is_auto_rejoin = false,
                       Callback cbfunc = null
)
```

#### 引数
- filepath  
  CHMPXスレーブノードプロセスを起動したときの設定ファイル（iniファイルなど）と同じファイルを指定します。
- is_auto_rejoin  
  trueを指定した場合、CHMPXスレーブノードプロセスが起動するまでブロックします。  
  falseを指定した場合、CHMPXスレーブノードプロセスが起動していないときにはエラーとなります。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true, function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('initializeOnSlave', Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.on('initializeOnSlave', function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  ```
- onInitializeOnSlave(Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.onInitializeOnSlave(function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  ```

#### 注意
メソッド引数is_auto_rejoinをfalseで呼び出した場合、CHMPXスレーブノードプロセスが起動していないときにはすぐにエラーとして本メソッド呼び出しは完了します。  
is_auto_rejoinをtrueで呼び出した場合、CHMPXスレーブノードプロセスが起動していないときには、起動するまで本メソッドはブロックされます。  
CHMPXプロセスがダウンした場合に再起動まで待った後、処理を行うようにするには、この引数をtrueとすることで、クライアントプログラムを簡単に実装できます。

### <a name="CHMPXNODE-OPEN"> ChmpxNode::Open()
ChmpxNodeオブジェクトをCHMPXスレーブノード側に接続し、メッセージIDを取得します。  
ChmpxNodeオブジェクトは予めスレーブノード用に初期化されている必要があります。

#### 書式
```
Buffer Open(bool     no_giveup_rejoin = false,
            Callback cbfunc = null
)
```

#### 引数
- no_giveup_rejoin  
  trueを指定した場合、CHMPXスレーブノードプロセスが起動するまでブロックします。  
  falseを指定した場合、CHMPXスレーブノードプロセスが起動していないときには、CHMPXスレーブノードプロセスに設定された試行上限回数まで試行されます。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error, Buffer msgid)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了時には、メッセージIDを返します。エラー時には（**null**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.close(msgid);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  chmpxslaveobj.open(true, function(error, msgid){
      if(null !== error || null == msgid){
          console_log('failed open msgid.');
      }else{
          chmpxslaveobj.close(msgid);
      }
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('open', Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  chmpxslaveobj.on('open', function(error, msgid){
      if(null !== error || null == msgid){
          console_log('failed open msgid.');
      }else{
          chmpxslaveobj.close(msgid);
      }
  });
  
  chmpxslaveobj.open(true);
  ```
- onOpen(Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  chmpxslaveobj.onOpen(function(error, msgid){
      if(null !== error || null == msgid){
          console_log('failed open msgid.');
      }else{
          chmpxslaveobj.close(msgid);
      }
  });
  
  chmpxslaveobj.open(true);
  ```

#### 注意
ChmpxNodeオブジェクトは予めスレーブノード用に初期化されている必要があります。  
no_giveup_rejoin引数にtrueを指定した場合、CHMPXスレーブノードプロセスが起動するまでブロックします。  
この引数にfalseを指定した場合、CHMPXスレーブノードプロセスが起動していないときには、試行上限回数まで接続が試行されます。  
試行上限回数は、CHMPXスレーブノードプロセスの起動時に設定されています。

### <a name="CHMPXNODE-CLOSE"> ChmpxNode::Close()
CHMPXスレーブノードに接続したメッセージIDを破棄（クローズ）します。  

#### 書式
```
bool Close(Buffer   msgid,
           Callback cbfunc = null
)
```

#### 引数
- msgid  
  ChmpxNode::Open()で取得したCHMPXスレーブノードに接続されたメッセージIDを指定します。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.close(msgid);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.close(msgid, function(error){
      if(null !== error){
          console_log('failed close msgid.');
      }
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('close', Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.on('close', function(error){
      if(null !== error){
          console_log('failed close msgid.');
      }
  });
  
  chmpxslaveobj.close(msgid);
  ```
- onClose(Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.onClose(function(error){
      if(null !== error){
          console_log('failed close msgid.');
      }
  });
  
  chmpxslaveobj.close(msgid);
  ```

### <a name="CHMPXNODE-SEND"> ChmpxNode::Send()
CHMPXスレーブノード側に接続したChmpxNodeオブジェクトからCHMPXサーバーノード側にデータを送ります。

#### 書式
```
int Send(Buffer   msgid,
         Buffer   body,
         bool     is_routing = true,
         Callback cbfunc = null
)
```

#### 引数
- msgid  
  CHMPXスレーブノード側クライアント用にChmpxNode::Open()メソッドでオープンしたメッセージIDを指定します。
- body  
  送信するデータを指定します。
- is_routing  
  CHMPXプロセスのメッセージ配送設定がルーティングとなっている場合、送信データをルーティングさせるか否かを指定します。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error, int receivercount)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了時には、受信したCHMPXサーバーノード数を返します。エラー時には（**-1**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  chmpxslaveobj.close(msgid);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true, function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('send', Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.on('send', function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  ```
- onSend(Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.onSend(function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  ```

#### 注意
CHMPXサーバーノードプロセスは、設定により多重化をすることができます。  
多重化されたCHMPXサーバーノードに対してスレーブノードからデータを送る場合、目的のCHMPXサーバーノードに接続できないとき、補助的なCHMPXサーバーノードにデータをルーティング配送することができます。  
このメソッド引数is_routingをtrueに設定した場合、CHMPXサーバーノードプロセスが多重化されていれば、ルーティング配送します。  
この引数をfalseにすると、送信データはルーティング配送されません。

### <a name="CHMPXNODE-BROADCAST"> ChmpxNode::Broadcast()
CHMPXスレーブノード側に接続したChmpxNodeオブジェクトからすべてのCHMPXサーバーノード側にデータを送ります。

#### 書式
```
int Broadcast(Buffer   msgid,
              Buffer   body,
              Callback cbfunc = null
)
```

#### 引数
- msgid  
  CHMPXスレーブノード側クライアント用にChmpxNode::Open()メソッドでオープンしたメッセージIDを指定します。
- body  
  送信するデータを指定します。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error, int receivercount)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了時には、受信したCHMPXサーバーノード数を返します。エラー時には（**-1**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.broadcast(msgid, Buffer.from('send data.'));
  
  chmpxslaveobj.close(msgid);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.broadcast(msgid, Buffer.from('send data.'), function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('broadcast', Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.on('broadcast', function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.broadcast(msgid, Buffer.from('send data.'));
  ```
- onBroadcast(Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.onBroadcast(function(error, receivercount){
      if(null !== error || -1 == receivercount){
          console_log('failed sending.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.broadcast(msgid, Buffer.from('send data.'));
  ```

### <a name="CHMPXNODE-RECEIVE-SLAVE"> ChmpxNode::Receive() - スレーブノード用
CHMPXスレーブノード側に接続したChmpxNodeオブジェクトで、CHMPXサーバーノード側からのデータを受信します。

#### 書式
同期と非同期によって関数の引数が異なります。  
- 同期  
  ```
  bool Receive(Buffer   msgid,
               Array    outarr,
               int      timeout_ms = 0
  )
  ```
- 非同期  
  ```
  bool Receive(Buffer   msgid,
               int      timeout_ms = 0,
               Callback cbfunc = null
  )
  ```

#### 引数
- msgid  
  CHMPXスレーブノード側クライアント用にChmpxNode::Open()メソッドでオープンしたメッセージIDを指定します。
- outarr  
  同期として本メソッドを使用する場合に受信データのために**Array**を指定します。  
  データ受信に成功した場合、outarr[0]には`Binary compkt`（送信されたCHMPXサーバーノードの情報）、outarr[1]には`Buffer data`（受信したデータ）が設定されます。
- timeout_ms  
  受信タイムアウトを**ミリ秒**で指定します。  
  受信タイムアウトを設定しない場合は、**0**を指定します。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error, Binary compkt, Buffer data)
  ```
  エラー発生時にはerrorはnull以外の値となります。  
  `Binary compkt`は、送信されたCHMPXサーバーノードの情報が設定されます。  
  `Buffer data`は、受信したデータが設定されます。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  var buffarr = new Array();
  chmpxslaveobj.receive(msgid, buffarr, 1000);
  
  chmpxslaveobj.close(msgid);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  chmpxslaveobj.receive(msgid, 1000, function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
      chmpxslaveobj.close(msgid);
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('receive', Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  chmpxslaveobj.on('receive', function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.receive(msgid, buffarr, 1000);
  ```
- onReceive(Callback cbfunc)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  chmpxslaveobj.onReceive(function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
      chmpxslaveobj.close(msgid);
  });
  
  chmpxslaveobj.receive(msgid, buffarr, 1000);
  ```

#### 注意
同期の場合のoutarr引数には、非同期の時のCallback関数の`Binary compkt`と`Buffer data`が配列に設定されます。

### <a name="CHMPXNODE-RECEIVE-SERVER"> ChmpxNode::Receive() - サーバーノード用
CHMPXサーバーノード側に接続したChmpxNodeオブジェクトで、CHMPXスレーブノード側からのデータを受信します。

#### 書式
同期と非同期によって関数の引数が異なります。  
- 同期  
  ```
  bool Receive(Array	outarr,
               int      timeout_ms = 0,
               bool     no_giveup_rejoin = false
  )
  ```
- 非同期  
  ```
  bool Receive(int      timeout_ms = 0,
               bool     no_giveup_rejoin = false,
               Callback cbfunc = null
  )
  ```

#### 引数
- outarr  
  同期として本メソッドを使用する場合に受信データのために**Array**を指定します。  
  データ受信に成功した場合、outarr[0]には`Binary compkt`（送信されたCHMPXサーバーノードの情報）、outarr[1]には`Buffer data`（受信したデータ）が設定されます。
- timeout_ms  
  受信タイムアウトを**ミリ秒**で指定します。  
  受信タイムアウトを設定しない場合は、**0**を指定します。
- no_giveup_rejoin  
  trueを指定した場合、CHMPXサーバーノードプロセスが起動するまでブロックします。  
  falseを指定した場合、CHMPXサーバーノードプロセスが起動していないときには、CHMPXサーバーノードプロセスに設定された試行上限回数まで試行されます。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error, Binary compkt, Buffer data)
  ```
  エラー発生時にはerrorはnull以外の値となります。  
  `Binary compkt`は、送信されたCHMPXスレーブノードの情報が設定されます。  
  `Buffer data`は、受信したデータが設定されます。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  ```
- 非同期（Callback）  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.receive(1000, true, function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
      chmpxserverobj.close(msgid);
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('receive', Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.on('receive', function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
  });
  
  chmpxserverobj.receive(buffarr, 1000, true);
  ```
- onReceive(Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.onReceive(function(error, compkt, data){
      if(null !== error){
          console_log('failed receiving.');
      }
  });
  
  chmpxserverobj.receive(1000, true);
  ```

#### 注意
同期の場合のoutarr引数には、非同期の時のCallback関数の`Binary compkt`と`Buffer data`が配列に設定されます。

### <a name="CHMPXNODE-REPLY"> ChmpxNode::Reply()
CHMPXサーバーノード側に接続したChmpxNodeオブジェクトからCHMPXスレーブノード側にデータを返信します。

#### 書式
```
bool Reply(Buffer   compkt
          Buffer   body,
          Callback cbfunc = null
)
```

#### 引数
- compkt  
  CHMPXサーバーノード側のChmpxNode::Receive()でデータを受信したときに受け取る`Binary compkt`を指定します。  
  `Binary compkt`にはそのデータを送信してきたCHMPXスレーブノードの情報が入っています。この情報を元に送信元にデータを返信します。
- body  
  返信するデータを指定します。
- cbfunc  
  本関数呼び出しを非同期で処理するとき、Callback関数を指定します。  
  Callback関数の書式は以下になります。  
  ```
  function(Error error)
  ```
  エラー発生時にはerrorはnull以外の値となります。

#### 返り値
正常終了（**true**）もしくは失敗（**false**）を返します。  
Callback関数が指定されている場合には、常に**true**が返されます。

#### サンプル
- 同期  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  
  chmpxserverobj.reply(buffarr[0], Buffer.from('reply data.'));
  ```
- 非同期（Callback）  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.receive(buffarr, 1000, true);
  
  chmpxserverobj.reply(buffarr[0], Buffer.from('reply data.'), function(error){
      if(null !== error){
          console_log('failed replying.');
      }
  });
  ```

#### イベントハンドラ
Callback関数を指定せず、イベントハンドラを設定して非同期処理をすることができます。  
以下の2つの方法で非同期処理を記述できます。
- on('reply', Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  
  chmpxserverobj.on('reply', function(error){
      if(null !== error){
          console_log('failed replying.');
      }
  });
  
  chmpxserverobj.reply(buffarr[0], Buffer.from('reply data.'));
  ```
- onReply(Callback cbfunc)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  
  chmpxserverobj.onReply(function(error){
      if(null !== error){
          console_log('failed replying.');
      }
  });
  
  chmpxserverobj.reply(buffarr[0], Buffer.from('reply data.'));
  ```

#### 注意
このメソッドはCHMPXサーバーノード側のクライアントプログラムが、CHMPXスレーブノードから受け取ったデータに対して、レスポンスを送り返すために利用されることを目的とします。  
送信元のCHMPXスレーブノードにデータを返信するため、データ受信時に受け取った`Binary compkt`を使います。

### <a name="CHMPXNODE-ISCHMPXEXIT"> ChmpxNode::IsChmpxExit()
CHMPXプロセスが起動しているか確認します。

#### 書式
```
bool IsChmpxExit(void)
```

#### 引数
なし

#### 返り値
CHMPXプロセスが起動している場合には**false**を返し、起動していない場合は**true**を返します。  

#### サンプル
- サーバーノード  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.ischmpxexit();
  ```
- スレーブノード  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  chmpxslaveobj.ischmpxexit();
  ```
