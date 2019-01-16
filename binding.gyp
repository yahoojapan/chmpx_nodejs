#
# CHMPX
#
# Copyright 2015 Yahoo! JAPAN corporation.
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
				"src/chmpx.cc",
				"src/chmpx_node.cc",
				"src/chmpx_cbs.cc"
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
				"-Wno-deprecated-declarations"
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
# VIM modelines
#
# vim:set ts=4 fenc=utf-8:
#
