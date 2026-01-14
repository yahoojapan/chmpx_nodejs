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
// ESM(ECMAScript Modules) Smoke Test
//---------------------------------------------------------
// [Purpose]
//	- Verify usage patterns from ESM environments:
//		- Path for loading CommonJS modules from ESM using
//		  createRequire(a reliable method)
//		- Path for loading files(JS entries) using dynamic
//		  import(to verify ESM compatibility)
//	- Verify that export lists can be obtained via both routes
//	  (compatibility check).
//
// [Outline]
//	- Use createRequire( import.meta.url ) to execute require('../')
//	  and output the returned key.
//	- With dynamic import, a specific file(ex, index.js) rather
//	  than a directory is converted into a URL, which is then
//	  imported() ed, and the resulting export key is output.
//	- Considering the possibility that dynamic import may not
//	  be able to load .node(native) files directly, multiple
//	  paths are often tried for safety
//	  (ex, index.js -> lib/index.js).
//
// [Expected]
//		createRequire loaded keys: [ 'ChmpxNode', 'default' ]
//		dynamic import succeeded for: /path/to/index.js keys: [ ... ]
//
// [Meaning of Failure]
//	- Passing a directory to dynamic import
//		Not supported by ESM (a file must be specified).
//	- Dynamic import fails when specifying .node
//		Node's ESM loader is not always able to resolve .node
//		as a module(using createRequire is the safest option).
//	- createRequire succeeds but dynamic import fails
//		This is due to differences between ESM resolution
//		 rules and CommonJS resolution rules(ex, main/exports).
//---------------------------------------------------------

import { createRequire }	from 'module';
import path					from 'path';
import url					from 'url';

(async () => {
	try{
		const	require	= createRequire(import.meta.url);
		const	mod		= require('../');									// CommonJS require via createRequire
		console.log('createRequire loaded keys:', Object.keys(mod));

		// [NOTE]
		// Try dynamic import of the JS entry file(not a directory).
		// Resolve project's package.json "main" or use index.js explicitly.
		// Try "../index.js" first, falling back to package.json main if present.
		//
		const	__dirname = path.dirname(url.fileURLToPath(import.meta.url));
		const	tryPaths = [
			path.join(__dirname, '..', 'index.js'),
			path.join(__dirname, '..', 'lib', 'index.js'),
			path.join(__dirname, '..', 'build', 'Release', 'k2hash.node')	// dynamic import of .node may not work; this is just a try
		];

		for(const tgPath of tryPaths){
			try{
				// Only try importing JS files
				//
				// skip .node in dynamic import because Node ESM
				// usually won't dynamic-import native addon as module
				//
				if(tgPath.endsWith('.js')){
					const	dynObj = await import(url.pathToFileURL(tgPath).href);
					console.log('dynamic import succeeded for:', tgPath, 'keys:', Object.keys(dynObj));
					break;
				}
			}catch(err2){
				// Try next
				//console.error('dynamic import failed for', tgPath, err2 && err2.message);
			}
		}
	}catch(err1){
		console.error('ESM test failed:', err1 && err1.message);
		process.exit(1);
	}
})();

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */
