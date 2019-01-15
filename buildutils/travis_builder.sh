#!/bin/sh
#
# Utility helper tools for Travis CI by AntPickax
#
# Copyright 2018 Yahoo Japan Corporation.
#
# AntPickax provides utility tools for supporting autotools
# builds.
#
# These tools retrieve the necessary information from the
# repository and appropriately set the setting values of
# configure, Makefile, spec,etc file and so on.
# These tools were recreated to reduce the number of fixes and
# reduce the workload of developers when there is a change in
# the project configuration.
# 
# For the full copyright and license information, please view
# the license file that was distributed with this source code.
#
# AUTHOR:   Takeshi Nakatani
# CREATE:   Tue Dec 18 2018
# REVISION:
#

#
# Helper for docker on Travis CI
#
func_usage()
{
	echo ""
	echo "Usage:  $1 [-pcuser <user>] [-pcrepo <repository name>] <package name>..."
	echo "        -pcuser            specify packagecloud.io repository user name(optional)"
	echo "        -pcrepo            specify packagecloud.io repository name(optional)"
	echo "        <package name>...  specify package names needed before building"
	echo "        -h                 print help"
	echo "Environments"
	echo "        TRAVIS_TAG         if the current build is for a git tag, this variable is set to the tag’s name"
	echo "        FORCE_PUBLISH_PKG  if this env is 'true', force packaging and publishing anytime"
	echo "        NPM_TOKEN          specify NPM token for publishing or checking package(must not be null)"
	echo "        NODE_MAJOR_VERSION specify Node.js major version number(6, 8, 10, ...)"
	echo "        USE_PC_REPO        if this env is 'true', use packagecloud.io repository"
	echo "        PUBLISHER          if this env is 'true', do publish npm package."
	echo ""
}

#
# Functions
#
prn_cmd()
{
	echo ""
	echo "$ $@"
}

run_cmd()
{
	echo ""
	echo "$ $@"
	$@
	if [ $? -ne 0 ]; then
		echo "[ERROR] ${PRGNAME} : \"$@\"" 1>&2
		exit 1
	fi
}

#
# Variables
#
PRGNAME=`basename $0`
MYSCRIPTDIR=`dirname $0`
MYSCRIPTDIR=`cd ${MYSCRIPTDIR}; pwd`
SRCTOP=`cd ${MYSCRIPTDIR}/..; pwd`

#
# Check options
#
INSTALLER_BIN="apt-get"
PCUSER=""
PCREPO=""
INSTALL_PACKAGES=""
while [ $# -ne 0 ]; do
	if [ "X$1" = "X" ]; then
		break

	elif [ "X$1" = "X-h" -o "X$1" = "X-H" -o "X$1" = "X--help" -o "X$1" = "X--HELP" ]; then
		func_usage $PRGNAME
		exit 0

	elif [ "X$1" = "X-pcuser" -o "X$1" = "X-PCUSER" ]; then
		if [ "X${PCUSER}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set packagecloud.io user name." 1>&2
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : -pcuser option is specified without parameter." 1>&2
			exit 1
		fi
		PCUSER=$1

	elif [ "X$1" = "X-pcrepo" -o "X$1" = "X-PCREPO" ]; then
		if [ "X${PCREPO}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set packagecloud.io repository name." 1>&2
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : -pcrepo option is specified without parameter." 1>&2
			exit 1
		fi
		PCREPO=$1

	else
		if [ "X${INSTALL_PACKAGES}" = "X" ]; then
			INSTALL_PACKAGES=$1
		else
			INSTALL_PACKAGES="${INSTALL_PACKAGES} $1"
		fi
	fi
	shift
done

#
# Check environment for packaging
#
IS_PUBLISH_TEST=0
IS_PUBLISH_REQUEST=0
IS_PUBLISHER=0
if [ "X${TRAVIS_PULL_REQUEST}" != "Xfalse" ]; then
	echo "[MESSAGE] This build is run by Pull Request(PR), then do not test packaging." 1>&2
else
	if [ "X${TRAVIS_TAG}" != "X" -o "X${FORCE_PUBLISH_PKG}" = "Xtrue" -o "X${FORCE_PUBLISH_PKG}" = "XTRUE" ]; then
		if [ "X${NPM_TOKEN}" = "X" ]; then
			echo "[ERROR] ${PRGNAME} : need to publish packages, but NPM token is not specified." 1>&2
			exit 1
		fi
		IS_PUBLISH_REQUEST=1
	fi
	IS_PUBLISH_TEST=1
fi
if [ "X${PUBLISHER}" = "Xtrue" -o "X${PUBLISHER}" = "XTRUE" ]; then
	IS_PUBLISHER=1
fi

#
# Check Node.js version
#
if [ "X${NODE_MAJOR_VERSION}" = "X" ]; then
	#
	# Default version is 10.x
	#
	NODE_MAJOR_VERSION=10
fi
expr ${NODE_MAJOR_VERSION} + 0 >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "[ERROR] ${PRGNAME} : NODE_MAJOR_VERSION(=${NODE_MAJOR_VERSION}) environment must be number." 1>&2
	exit 1
fi
if [ ${NODE_MAJOR_VERSION} -lt 6 ]; then
	echo "[ERROR] ${PRGNAME} : NODE_MAJOR_VERSION(=${NODE_MAJOR_VERSION}) environment must be after 6." 1>&2
	exit 1
fi
echo ""
echo "[MESSAGE] Start - Node.js version is ${NODE_MAJOR_VERSION}.x"

#
# Check curl & install it
#
curl --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
	run_cmd ${INSTALLER_BIN} update -y -qq
	run_cmd ${INSTALLER_BIN} install -y -qq curl
fi

#
# Set package repository on packagecloud.io
#
if [ "X${USE_PC_REPO}" = "Xtrue" -o "X${USE_PC_REPO}" = "XTRUE" ]; then
	if [ "X${PCUSER}" = "X" -o "X${PCREPO}" = "X" ]; then
		echo "[ERROR] ${PRGNAME} : Not specified username or repository for packagecloud.io" 1>&2
		exit 1
	fi
	PC_REPO_ADD_SH="script.deb.sh"

	prn_cmd "curl -s https://packagecloud.io/install/repositories/${PCUSER}/${PCREPO}/${PC_REPO_ADD_SH} | bash"
	curl -s https://packagecloud.io/install/repositories/${PCUSER}/${PCREPO}/${PC_REPO_ADD_SH} | bash
	if [ $? -ne 0 ]; then
		echo "[ERROR] ${PRGNAME} : could not add packagecloud.io repository." 1>&2
		exit 1
	fi
fi

#
# Set package repository for nodejs
# See: https://github.com/nodesource/distributions/blob/master/README.md
#
prn_cmd "curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | bash -"
curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | bash -
if [ ${NODE_MAJOR_VERSION} -eq 6 ]; then
	#
	# Node.js 6.x needs to set following file.
	# If not set this file, probably install 8.x and not found npm command.
	# See: https://github.com/nodesource/distributions/issues/761#issuecomment-443072330
	#
	mkdir -p /etc/apt/preferences.d
	echo -e "Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 600" | sed 's/^-e //g' > /etc/apt/preferences.d/nodesource
fi

#
# update
#
run_cmd ${INSTALLER_BIN} update -y -qq

#
# Install packages
#
run_cmd ${INSTALLER_BIN} install -y -qq git gcc g++ make
run_cmd ${INSTALLER_BIN} install -y nodejs

if [ "X${INSTALL_PACKAGES}" != "X" ]; then
	run_cmd ${INSTALLER_BIN} install -y ${INSTALL_PACKAGES}
fi

#
# Print Node.js version
#
run_cmd node -v
run_cmd npm version
if [ ${NODE_MAJOR_VERSION} -gt 6 ]; then
	#
	# do not use npx now, because Node.js 6x does not have this.
	#
	run_cmd npx -v
fi

#
# Copy sources ( to build under /tmp )
#
run_cmd cp -rp ${SRCTOP} /tmp
TMPSRCTOP=`basename ${SRCTOP}`
TMPSRCTOP="/tmp/${TMPSRCTOP}"

#
# Install node packages and Build
#
run_cmd cd ${TMPSRCTOP}
run_cmd npm install
run_cmd npm run build

#
# Test and Packaging
#
if [ ${IS_PUBLISH_TEST} -ne 1 ]; then
	#
	# Test by npm
	#
	run_cmd npm run test
else
	#
	# Using publish-please tools for testing and packaging
	#

	#
	# Create .npmrc file
	#
	prn_cmd "echo \"//registry.npmjs.org/:_authToken=\${NPM_TOKEN}\" > ~/.npmrc"
	echo "//registry.npmjs.org/:_authToken=\${NPM_TOKEN}" > ~/.npmrc
	if [ $? -ne 0 ]; then
		echo "[ERROR] ${PRGNAME} : could not create .npmrc file" 1>&2
		exit 1
	fi

	#
	# Modify .publishrc file if need
	#
	if [ "X${TRAVIS_TAG}" = "X" ]; then
		#
		# If not tagging, skip checking tag name
		#
		#grep -l '"uncommittedChanges": true' .publishrc | xargs sed -i.BAK -e 's/"uncommittedChanges": true/"uncommittedChanges": false/g'
		grep -l '"gitTag": true' .publishrc | xargs sed -i.BAK -e 's/"gitTag": true/"gitTag": false/g'
	fi
	if [ ${NODE_MAJOR_VERSION} -eq 6 ]; then
		#
		# Node.js 6.x has old npm
		# - vulnerableDependencies needs npm version 6.1.0 or above.
		# - sensitiveData needs npm version 5.9.0 or above.
		#
		#grep -l '"uncommittedChanges": true' .publishrc | xargs sed -i.BAK -e 's/"uncommittedChanges": true/"uncommittedChanges": false/g'
		grep -l '"vulnerableDependencies": true' .publishrc | xargs sed -i.BAK -e 's/"vulnerableDependencies": true/"vulnerableDependencies": false/g'
		grep -l '"sensitiveData": true' .publishrc | xargs sed -i.BAK -e 's/"sensitiveData": true/"sensitiveData": false/g'
	fi
	rm -f .publishrc.BAK
	run_cmd cat .publishrc

	#
	# Option for publish-please command
	#
	if [ ${IS_PUBLISH_REQUEST} -eq 1 -a ${IS_PUBLISHER} -eq 1 ]; then
		PUBLISH_PLEASE_OPT=""
	else
		PUBLISH_PLEASE_OPT="--dry-run"
	fi

	#
	# Publish( or test it )
	#
	run_cmd npm run publish-please ${PUBLISH_PLEASE_OPT}

	if [ ${IS_PUBLISH_REQUEST} -eq 1 -a ${IS_PUBLISHER} -eq 1 ]; then
		echo "[NOTICE] Published npm package, MUST CHECK NPM repository!!"
	fi
fi

echo ""
echo "[MESSAGE] Finish - Node.js version is ${NODE_MAJOR_VERSION}.x"

exit 0

#
# VIM modelines
#
# vim:set ts=4 fenc=utf-8:
#
