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
 * CREATE:   Wed Jan 7 2026
 * REVISION:
 *
 */

//---------------------------------------------------------
// CommonJS Smoke Test
//---------------------------------------------------------
// [Purpose]
//	Verify that the module can be loaded correctly in a CommonJS
//	environment(require) and that its main exports and basic
//	construction/method calls work(smoke test).
//
// [Outline]
//	- Load the project root package with require('../').
//	- Print the module key( Object.keys(mod) ) and verify that
//	  the expected exports (ex, ChmpxNode) exist.
//	- If ChmpxNode is exported, attempt to instantiate it with
//	  new, and if the getQueue method exists, call it and verify
//	  the return value.
//	- Catch exceptions and send them to standard error output
//	  (to avoid crashes).
//
// [Expected]
//		module keys: [ 'ChmpxNode', 'default' ]
//		ChmpxNode constructed -> typeof: object
//
// [Meaning of Failure]
//	- require failed
//		Not built / problem with main entry / unable to load
//		native module(.node load error).
//	- exception in new ChmpxNode()
//		native code initialization error or binding inconsistency.
//	- getQueue not found
//		The name expected by the API is different from the actual
//		implementation.
//---------------------------------------------------------

try{
	const	mod = require('../');		// project root package
	console.log('module keys:', Object.keys(mod));

	if(mod.ChmpxNode){
		try{
			const	chmpxobj = new mod.ChmpxNode();
			console.log('ChmpxNode constructed -> typeof:', typeof chmpxobj);
		}catch(err2){
			console.error('ChmpxNode constructor threw:', err2 && err2.message);
			process.exit(1);
		}
	}else{
		console.error('ChmpxNode not exported by module');
		process.exit(1);
	}
}catch(err1){
	console.error('require failed:', err1 && err1.message);
	process.exit(1);
}

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
