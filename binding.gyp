{
	"variables": {
		"coverage":	"false",
		"openssl_fips": ""
	},
	"targets": [
		{
			"target_name":	"chmpx",
			"sources": [
				"src/chmpx.cc",
				"src/chmpx_node.cc",
				"src/chmpx_cbs.cc"
			],
			"include_dirs": [
				"<!(node -e \"incpath = require('node-addon-api').include; if(incpath.length && incpath[0] === '\\\"' && incpath[incpath.length - 1] === '\\\"') incpath = incpath.slice(1, -1); process.stdout.write(incpath)\")",
				"<(module_root_dir)/node_modules/node-addon-api"
			],
			"dependencies": [
				"<!(node -p \"require('node-addon-api').gyp\")"
			],
			"cflags!": [
				"-fno-exceptions"
			],
			"cflags_cc!": [
				"-fno-exceptions"
			],
			"cflags_cc": [
				"-std=c++17"
			],
			"defines": [
				"NAPI_CPP_EXCEPTIONS"
			],
			"link_settings": {
				"libraries": [
					"-lchmpx"
				]
			}
		}
	]
}
