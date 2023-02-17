#
# CHMPX
#
# Copyright 2015 Yahoo Japan Corporation.
#
# CHMPX is inprocess data exchange by MQ with consistent hashing.
# CHMPX is made for the purpose of the construction of
# original messaging system and the offer of the client
# library.
# CHMPX transfers messages between the client and the server/
# slave. CHMPX based servers are dispersed by consistent
# hashing and are automatically laid out. As a result, it
# provides a high performance, a high scalability.
#
# For the full copyright and license information, please view
# the license file that was distributed with this source code.
#
# AUTHOR:   Taku Ishihara
# CREATE:   Tue Oct 6 2015
# REVISION:
#

{
	"variables":	{
		"coverage":	"false"
	},
	"targets":		[
		{
			"target_name":	"chmpx",
			"sources":		[
				"chmpx.cc",
				"chmpx_node.cc",
				"chmpx_cbs.cc"
			],
			"cflags":		[
				#
				# We get too many deprecated message building with nodejs 0.12.x.
				# Those messages are depricated functions/methods, but we do not use those.
				# So that we ignore these deprecated warning here.
				#
				"-Wno-deprecated",
				#
				# For nodejs 9.x/10.x, it puts about MakeCallback / CreateDataProperty / DefineOwnProperty
				#
				"-Wno-deprecated-declarations",
				#
				# For nodejs 12.x/..., it suppress warnings: "'deprecated' attribute directive ignored"
				#
				"-Wno-attributes",
				#
				# nodejs/nan#807(https://github.com/nodejs/nan/issues/807#issuecomment-455750192)
				# recommends using the "-Wno-cast-function-type" to silence deprecations warnings
				# that appear with GCC 8.
				#
				"-Wno-cast-function-type"
			],
			"include_dirs":	[
				"<!(node -e \"require('nan')\")"
			],
			"libraries":	[
				"-lchmpx"
			]
		}
	]
}

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
