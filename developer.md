---
layout: contents
language: en-us
title: Developer
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: developerja.html
lang_opp_word: To Japanese
prev_url: build.html
prev_string: Build
top_url: index.html
top_string: TOP
next_url: environments.html
next_string: Environments
---

<!-- -----------------------------------------------------------　-->
# For developer

## [Common](#COMMON)
[Synchronous and Asynchronous](#ASYNCHRONOUS)  
[About Classes](#ABOUTCLASS)  

## [ChmpxNode Class](#CHMPXNODECLASS)
[ChmpxNode::InitializeOnServer()](#CHMPXNODE-INITIALIZEONSERVER)  
[ChmpxNode::InitializeOnSlave()](#CHMPXNODE-INITIALIZEONSLAVE)  
[ChmpxNode::Open()](#CHMPXNODE-OPEN)  
[ChmpxNode::Close()](#CHMPXNODE-CLOSE)  
[ChmpxNode::Send()](#CHMPXNODE-SEND)  
[ChmpxNode::Broadcast()](#CHMPXNODE-BROADCAST)  
[ChmpxNode::Receive() - For slave node](#CHMPXNODE-RECEIVE-SLAVE)  
[ChmpxNode::Receive() - For server node](#CHMPXNODE-RECEIVE-SERVER)  
[ChmpxNode::Reply()](#CHMPXNODE-REPLY)  
[ChmpxNode::IsChmpxExit()](#CHMPXNODE-ISCHMPXEXIT)  

<!-- -----------------------------------------------------------　-->
***

## <a name="COMMON"> Common
### <a name="ASYNCHRONOUS"> Synchronous and Asynchronous
The methods of the classes provided by CHMPX Node.js addon library support synchronous and asynchronous processing by specifying the callback function.  
Methods that support asynchronous processing can accept the arguments of the callback function.  
In addition, these can specify event handlers as **on** or **onXXXXX** as asynchronous processing.  
Developers can perform asynchronous processing using callback functions or event handlers.  
Callback function arguments and event handlers are not specified, these methods act as synchronization processes.

### <a name="ABOUTCLASS"> About Classes
CHMPX Node.js addon library provides **ChmpxNode** class.
Initialize this ChmpxNode class as a client of the server node and communicate as a server node side client.
It initializes it as a client of the slave node and communicates as a slave node side client.

<!-- -----------------------------------------------------------　-->
***

## <a name="CHMPXNODECLASS"> ChmpxNode Class
This is the main class provided by CHMPX Node.js addon library.  
You can use this class to communicate as server node side client and slave node side client.

A sample to create this class object is shown below.
- Client on CHMPX server node  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```
- Client on CHMPX slave node  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true)
  ```

Below are the methods of the ChmpxNode class and those explanation.

### <a name="CHMPXNODE-INITIALIZEONSERVER"> ChmpxNode::InitializeOnServer()
This method initializes ChmpxNode object for on chmpx server node.

#### Format
```
bool InitializeOnServer(String   filepath,
                        bool     is_auto_rejoin = false,
                        Callback cbfunc = null
)
```

#### Arguments
- filepath  
  Specify the same file as the configuration file(such as *.ini) when starting CHMPX server node process.
- is_auto_rejoin  
  Specify true, it blocks until the CHMPX server node process starts.  
  If false is specified, an error occurs when the CHMPX server node process is not running.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error)
  ```
  If an error occurs, error is not null.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  ```
- Asynchronous(Callback function)  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true, function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  ```

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
If you call the method argument is_auto_rejoin with false, it will return an error immediately when the CHMPX server node process is not running. 
If is_auto_rejoin is set to true, when the CHMPX server node process is not running, this method will be blocked until it is started up.  
To wait until the CHMPX process is restarted, you can easily implement the client program by setting this argument to true.

### <a name="CHMPXNODE-INITIALIZEONSLAVE"> ChmpxNode::InitializeOnSlave()
This method initializes ChmpxNode object for on chmpx slave node.

#### Format
```
bool InitializeOnSlave(String   filepath,
                       bool     is_auto_rejoin = false,
                       Callback cbfunc = null
)
```

#### Arguments
- filepath  
  Specify the same file as the configuration file(such as *.ini) when starting CHMPX slave node process.
- is_auto_rejoin  
  Specify true, it blocks until the CHMPX slave node process starts.  
  If false is specified, an error occurs when the CHMPX slave node process is not running.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error)
  ```
  If an error occurs, error is not null.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  ```
- Asynchronous(Callback function)  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true, function(error){
      if(null !== error){
          console_log('failed initializing.');
      }
  });
  ```

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
If you call the method argument is_auto_rejoin with false, it will return an error immediately when the CHMPX slave node process is not running. 
If is_auto_rejoin is set to true, when the CHMPX slave node process is not running, this method will be blocked until it is started up.  
To wait until the CHMPX process is restarted, you can easily implement the client program by setting this argument to true.

### <a name="CHMPXNODE-OPEN"> ChmpxNode::Open()
Connect the ChmpxNode object to the CHMPX slave node side and obtain the message ID.  
The ChmpxNode object must be initialized in advance for the slave node.

#### Format
```
Buffer Open(bool     no_giveup_rejoin = false,
            Callback cbfunc = null
)
```

#### Arguments
- no_giveup_rejoin  
  Specify true, it blocks until the CHMPX slave node process starts.  
  If false is specified, when the CHMPX slave node process is not running, it is tried until the trial limit set in the CHMPX slave node process.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error, Buffer msgid)
  ```
  If an error occurs, error is not null.

#### Return Values
Return the message ID if success, and on error return **null**.  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.close(msgid);
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
The ChmpxNode object must be initialized in advance for the slave node.  
If no_giveup_rejoin is set to true, it blocks until the CHMPX slave node process starts up.  
If you specify false, if the CHMPX slave node process is not running, try to connect up to the trial upper limit.  
The maximum number of trials is set when the CHMPX slave node process is started.

### <a name="CHMPXNODE-CLOSE"> ChmpxNode::Close()
Discard(close) the message ID connected to the CHMPX slave node.

#### Format
```
bool Close(Buffer   msgid,
           Callback cbfunc = null
)
```

#### Arguments
- msgid  
  Specify the message ID connected to the CHMPX slave node acquired with ChmpxNode::Open().
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error)
  ```
  If an error occurs, error is not null.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave(true);
  
  var msgid = chmpxslaveobj.open(true);
  
  chmpxslaveobj.close(msgid);
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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
The data is sent from the ChmpxNode object connected to the CHMPX slave node side to the CHMPX server node side.

#### Format
```
int Send(Buffer   msgid,
         Buffer   body,
         bool     is_routing = true,
         Callback cbfunc = null
)
```

#### Arguments
- msgid  
  Specify the message ID connected to the CHMPX slave node acquired with ChmpxNode::Open().
- body  
  Specify the data to send.
- is_routing  
  When the message delivery setting of the CHMPX process is routing, specify whether or not to transmit the transmission data.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error, int receivercount)
  ```
  If an error occurs, error is not null.

#### Return Values
Return the CHMPX server node count which received the data for success, and on error return **-1**.  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.send(msgid, Buffer.from('send data.'), true);
  
  chmpxslaveobj.close(msgid);
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
The CHMPX server node process can be multiplexed according to the setting at startup.  
When sending data from a slave node to a multiplexed CHMPX server node, it can route it to an auxiliary CHMPX server node when it can not connect to the target CHMPX server node.  
If is_routing is set to true, if the CHMPX server node process is multiplexed, routing delivery is performed.  
If set to false, the transmitted data will not be routed and delivered.

### <a name="CHMPXNODE-BROADCAST"> ChmpxNode::Broadcast()
Data is sent from the ChmpxNode object connected to the CHMPX slave node side to all CHMPX server nodes.

#### Format
```
int Broadcast(Buffer   msgid,
              Buffer   body,
              Callback cbfunc = null
)
```

#### Arguments
- msgid  
  Specify the message ID connected to the CHMPX slave node acquired with ChmpxNode::Open().
- body  
  Specify the data to send.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error, int receivercount)
  ```
  If an error occurs, error is not null.

#### Return Values
Return the CHMPX server node count which received the data for success, and on error return **-1**.  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  var msgid = chmpxslaveobj.open();
  
  chmpxslaveobj.broadcast(msgid, Buffer.from('send data.'));
  
  chmpxslaveobj.close(msgid);
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

### <a name="CHMPXNODE-RECEIVE-SLAVE"> ChmpxNode::Receive() - For slave node
The ChmpxNode object connected to the CHMPX slave node receives the data from the CHMPX server node side.

#### Format
Function formats are different depending on synchronous and asynchronous.  
- Synchronous  
  ```
  bool Receive(Buffer   msgid,
               Array    outarr,
               int      timeout_ms = 0
  )
  ```
- Asynchronous  
  ```
  bool Receive(Buffer   msgid,
               int      timeout_ms = 0,
               Callback cbfunc = null
  )
  ```

#### Arguments
- msgid  
  Specify the message ID connected to the CHMPX slave node acquired with ChmpxNode::Open().
- outarr  
  When using this method as synchronization, specify **Array** for received data.  
  When data reception is successful, `Binary compkt`(information of the transmitted CHMPX server node) is set to outarr[0], `Buffer data`(received data) is set to outarr[1].
- timeout_ms  
  Specify the reception timeout in **milliseconds**(ms).  
  If you do not want to set the reception timeout, specify **0**.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error, Binary compkt, Buffer data)
  ```
  If an error occurs, error is not null.  
  `Binary compkt` is set to the information of the transmitted CHMPX server node.  
  The received data is set in `Buffer data`.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
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
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
In the case of synchronization, the callback functions `Binary compkt` and` Buffer data` for asynchronous are set in the array as the outarr argument.

### <a name="CHMPXNODE-RECEIVE-SERVER"> ChmpxNode::Receive() - For server node
The ChmpxNode object connected to the CHMPX server node receives data from the CHMPX slave node side.

#### Format
Function formats are different depending on synchronous and asynchronous.  
- Synchronous  
  ```
  bool Receive(Array	outarr,
               int      timeout_ms = 0,
               bool     no_giveup_rejoin = false
  )
  ```
- Asynchronous  
  ```
  bool Receive(int      timeout_ms = 0,
               bool     no_giveup_rejoin = false,
               Callback cbfunc = null
  )
  ```

#### Arguments
- outarr  
  When using this method as synchronization, specify **Array** for received data.  
  When data reception is successful, `Binary compkt`(information of the transmitted CHMPX server node) is set to outarr[0], `Buffer data`(received data) is set to outarr[1].
- timeout_ms  
  Specify the reception timeout in **milliseconds**(ms).  
  If you do not want to set the reception timeout, specify **0**.
- no_giveup_rejoin  
  If you specify true, it blocks until the CHMPX server node process starts.  
  If false is specified, when the CHMPX server node process is not running, it will be tried up to the limit set in the CHMPX server node process.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error, Binary compkt, Buffer data)
  ```
  If an error occurs, error is not null.  
  `Binary compkt` is set to the information of the transmitted CHMPX server node.  
  The received data is set in `Buffer data`.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
In the case of synchronization, the callback functions `Binary compkt` and` Buffer data` for asynchronous are set in the array as the outarr argument.

### <a name="CHMPXNODE-REPLY"> ChmpxNode::Reply()
Data is replied from the ChmpxNode object connected to the CHMPX server node to the CHMPX slave node side.

#### Format
```
bool Reply(Buffer   compkt
          Buffer   body,
          Callback cbfunc = null
)
```

#### Arguments
- compkt  
  Specify `Binary compkt` returned when receiving data with ChmpxNode::Receive() of CHMPX server node.  
  `Binary compkt` is the information of the CHMPX slave node that sent the data.  
  Based on this information you can reply data to the sender.
- body  
  Specify the data to reply.
- cbfunc  
  When using this method as asynchronous, the following prototype callback function can be specified.  
  ```
  function(Error error)
  ```
  If an error occurs, error is not null.

#### Return Values
This method returns success(true) or failure(false).  
When callback function is specified, true value is always returned.

#### Examples
- Synchronous  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  var buffarr = new Array();
  chmpxserverobj.receive(buffarr, 1000, true);
  
  chmpxserverobj.reply(buffarr[0], Buffer.from('reply data.'));
  ```
- Asynchronous(Callback function)  
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

#### Event handlers
You can use asynchronous processing by implementing an event handler without using callback function.  
Asynchronous processing can be described by the following two implementations.
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

#### Notes
This method is used by the client program of the CHMPX server node to reply to the CHMPX slave node.  
To return data to the source CHMPX slave node, use `Binary compkt` returned when receiving data.

### <a name="CHMPXNODE-ISCHMPXEXIT"> ChmpxNode::IsChmpxExit()
This method makes sure CHMPX process is running.

#### Format
```
bool IsChmpxExit(void)
```

#### Arguments
n/a

#### Return Values
Return **false** if the CHMPX process is running, and **true** if it is not running.

#### Examples
- On CHMPX server node  
  ```
  var chmpxnode      = require('chmpx');
  var chmpxserverobj = new chmpxnode();
  
  chmpxserverobj.initializeOnServer('server.ini', true);
  
  chmpxserverobj.ischmpxexit();
  ```
- On CHMPX slave node  
  ```
  var chmpxnode     = require('chmpx');
  var chmpxslaveobj = new chmpxnode();
  
  chmpxslaveobj.initializeOnSlave('slave.ini', true);
  
  chmpxslaveobj.ischmpxexit();
  ```
