#!/bin/sh
#
# Utility helper tools for Github Actions by AntPickax
#
# Copyright 2020 Yahoo Japan Corporation.
#
# AntPickax provides utility tools for supporting nodejs.
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
# CREATE:   Wed, Nov 18 2020
# REVISION: 1.0
#

#---------------------------------------------------------------------
# Helper for nodejs on Github Actions
#---------------------------------------------------------------------
func_usage()
{
	echo ""
	echo "Usage: $1 [options...]"
	echo ""
	echo "  Required option:"
	echo "    --help(-h)                                             print help"
	echo "    --nodejstype(-node)                       <version>    specify nodejs version(ex. \"12\" or \"12.x\" or \"12.0.0...\")"
	echo ""
	echo "  Option:"
	echo "    --nodejstype-vars-file(-f)                <file path>  specify the file that describes the package list to be installed before build(default is nodejstypevars.sh)"
	echo "    --npm-token(-token)                       <token>      npm token for uploading(specify when uploading)"
	echo "    --force-publisher(-fp)                    <version>    specify publisher node major version(ex. 10/11/12)."
	echo ""
	echo "  Option for packagecloud.io:"
	echo "    --use-packagecloudio-repo(-usepc)                      use packagecloud.io repository(default), exclusive -notpc option"
	echo "    --not-use-packagecloudio-repo(-notpc)                  not use packagecloud.io repository, exclusive -usepc option"
	echo "    --packagecloudio-owner(-pcowner)          <owner>      owner name of uploading destination to packagecloud.io, this is part of the repository path(default is antpickax)"
	echo "    --packagecloudio-download-repo(-pcdlrepo) <repository> repository name of installing packages in packagecloud.io, this is part of the repository path(default is stable)"
	echo ""
	echo "  Note:"
	echo "    This program uses the GITHUB_REF and GITHUB_EVENT_NAME environment variable internally."
	echo ""
}

#
# Utility functions
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
		echo "[ERROR] ${PRGNAME} : \"$@\""
		exit 1
	fi
}

#---------------------------------------------------------------------
# Common Variables
#---------------------------------------------------------------------
PRGNAME=`basename $0`
MYSCRIPTDIR=`dirname $0`
MYSCRIPTDIR=`cd ${MYSCRIPTDIR}; pwd`
SRCTOP=`cd ${MYSCRIPTDIR}/../..; pwd`

#---------------------------------------------------------------------
# Parse Options
#---------------------------------------------------------------------
echo "[INFO] ${PRGNAME} : Start the parsing of options."

OPT_NODEJS_TYPE=
OPT_NODEJS_TYPE_VARS_FILE=
OPT_FORCE_PUBLISHER=
OPT_USE_PC_REPO=
OPT_NPM_TOKEN=
OPT_PC_OWNER=
OPT_PC_DOWNLOAD_REPO=

while [ $# -ne 0 ]; do
	if [ "X$1" = "X" ]; then
		break

	elif [ "X$1" = "X-h" -o "X$1" = "X-H" -o "X$1" = "X--help" -o "X$1" = "X--HELP" ]; then
		func_usage $PRGNAME
		exit 0

	elif [ "X$1" = "X-node" -o "X$1" = "X-NODE" -o "X$1" = "X--nodejstype" -o "X$1" = "X--NODEJSTYPE" ]; then
		if [ "X${OPT_NODEJS_TYPE}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--nodejstype(-node)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--nodejstype(-node)\" option is specified without parameter."
			exit 1
		fi
		OPT_NODEJS_TYPE=$1

	elif [ "X$1" = "X-f" -o "X$1" = "X-F" -o "X$1" = "X--nodejstype-vars-file" -o "X$1" = "X--NODEJSTYPE-VARS-FILE" ]; then
		if [ "X${OPT_NODEJS_TYPE_VARS_FILE}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--nodejstype-vars-file(-f)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--nodejstype-vars-file(-f)\" option is specified without parameter."
			exit 1
		fi
		if [ ! -f $1 ]; then
			echo "[ERROR] ${PRGNAME} : $1 file is not existed, it is specified \"--ostype-vars-file(-f)\" option."
			exit 1
		fi
		OPT_NODEJS_TYPE_VARS_FILE=$1

	elif [ "X$1" = "X-fp" -o "X$1" = "X-FP" -o "X$1" = "X--force-publisher" -o "X$1" = "X--FORCE-PUBLISHER" ]; then
		if [ "X${OPT_IS_PUBLISH}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--force-publisher(-fp)\" or \"--not-publish(-np)\" option."
			exit 1
		fi
		shift
		expr $1 + 0 >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--force-publisher(-fp)\" option specify with Node.js major version(ex, 10/11/12...)."
			exit 1
		fi
		if [ $1 -le 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--force-publisher(-fp)\" option specify with Node.js major version(ex, 10/11/12...)."
			exit 1
		fi
		OPT_FORCE_PUBLISHER=$1

	elif [ "X$1" = "X-usepc" -o "X$1" = "X-USEPC" -o "X$1" = "X--use-packagecloudio-repo" -o "X$1" = "X--USE-PACKAGECLOUDIO-REPO" ]; then
		if [ "X${OPT_USE_PC_REPO}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PC_REPO="true"

	elif [ "X$1" = "X-notpc" -o "X$1" = "X-NOTPC" -o "X$1" = "X--not-use-packagecloudio-repo" -o "X$1" = "X--NOT-USE-PACKAGECLOUDIO-REPO" ]; then
		if [ "X${OPT_USE_PC_REPO}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PC_REPO="false"

	elif [ "X$1" = "X-token" -o "X$1" = "X-TOKEN" -o "X$1" = "X--npm-token" -o "X$1" = "X--NPM-TOKEN" ]; then
		if [ "X${OPT_NPM_TOKEN}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--npm-token(-token)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--npm-token(-token)\" option is specified without parameter."
			exit 1
		fi
		OPT_NPM_TOKEN=$1

	elif [ "X$1" = "X-pcowner" -o "X$1" = "X-PCOWNER" -o "X$1" = "X--packagecloudio-owner" -o "X$1" = "X--PACKAGECLOUDIO-OWNER" ]; then
		if [ "X${OPT_PC_OWNER}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--packagecloudio-owner(-pcowner)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--packagecloudio-owner(-pcowner)\" option is specified without parameter."
			exit 1
		fi
		OPT_PC_OWNER=$1

	elif [ "X$1" = "X-pcdlrepo" -o "X$1" = "X-PCDLREPO" -o "X$1" = "X--packagecloudio-download-repo" -o "X$1" = "X--PACKAGECLOUDIO-DOWNLOAD-REPO" ]; then
		if [ "X${OPT_PC_DOWNLOAD_REPO}" != "X" ]; then
			echo "[ERROR] ${PRGNAME} : already set \"--packagecloudio-download-repo(-pcdlrepo)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			echo "[ERROR] ${PRGNAME} : \"--packagecloudio-download-repo(-pcdlrepo)\" option is specified without parameter."
			exit 1
		fi
		OPT_PC_DOWNLOAD_REPO=$1
	fi
	shift
done

#
# Check only options that must be specified
#
if [ "X${OPT_NODEJS_TYPE}" = "X" ]; then
	echo "[ERROR] ${PRGNAME} : \"--nodejstype(-node)\" option is not specified."
	exit 1
else
	NODE_MAJOR_VERSION=`echo ${OPT_NODEJS_TYPE} | sed 's/[.]/ /g' | awk '{print $1}'`
	expr ${NODE_MAJOR_VERSION} + 0 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "[ERROR] ${PRGNAME} : \"--nodejstype(-node)\" option specify with Node.js version(ex, 10/10.x/10.0.0/...)."
		exit 1
	fi
	if [ ${NODE_MAJOR_VERSION} -le 0 ]; then
		echo "[ERROR] ${PRGNAME} : \"--nodejstype(-node)\" option specify with Node.js version(ex, 10/10.x/10.0.0/...)."
		exit 1
	fi
fi

#---------------------------------------------------------------------
# Load variables from file
#---------------------------------------------------------------------
echo "[INFO] ${PRGNAME} : Load local variables with an external file."

if [ "X${OPT_NODEJS_TYPE_VARS_FILE}" = "X" ]; then
	NODEJS_TYPE_VARS_FILE="${MYSCRIPTDIR}/nodejstypevars.sh"
elif [ ! -f ${OPT_NODEJS_TYPE_VARS_FILE} ]; then
	echo "[WARNING] ${PRGNAME} : not found ${OPT_NODEJS_TYPE_VARS_FILE} file, then default(nodejstypevars.sh) file is used."
	NODEJS_TYPE_VARS_FILE="${MYSCRIPTDIR}/nodejstypevars.sh"
else
	NODEJS_TYPE_VARS_FILE=${OPT_NODEJS_TYPE_VARS_FILE}
fi
if [ -f ${NODEJS_TYPE_VARS_FILE} ]; then
	echo "[INFO] ${PRGNAME} : Load ${NODEJS_TYPE_VARS_FILE} for local variables by Node.js version(${NODE_MAJOR_VERSION}.x)"
	. ${NODEJS_TYPE_VARS_FILE}
fi

#---------------------------------------------------------------------
# Merge other variables
#---------------------------------------------------------------------
echo "[INFO] ${PRGNAME} : Set and check local variables."

#
# Check GITHUB Environment
#
IN_PUSH_PROCESS=0
IN_PR_PROCESS=0
IN_SCHEDULE_PROCESS=0
if [ "X${GITHUB_EVENT_NAME}" = "Xpush" ]; then
	IN_PUSH_PROCESS=1
elif [ "X${GITHUB_EVENT_NAME}" = "Xpull_request" ]; then
	IN_PR_PROCESS=1
elif [ "X${GITHUB_EVENT_NAME}" = "Xschedule" ]; then
	IN_SCHEDULE_PROCESS=1
fi
PUBLISH_TAG_NAME=
if [ "X${GITHUB_REF}" != "X" ]; then
	echo ${GITHUB_REF} | grep 'refs/tags/' >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		PUBLISH_TAG_NAME=`echo ${GITHUB_REF} | sed 's#refs/tags/##g'`
	fi
fi

#
# Set variables for packagecloud.io
#
if [ "X${OPT_USE_PC_REPO}" = "Xfalse" ]; then
	USE_PC_REPO=0
else
	USE_PC_REPO=1
fi
if [ "X${OPT_NPM_TOKEN}" != "X" ]; then
	export NPM_TOKEN=${OPT_NPM_TOKEN}
else
	NPM_TOKEN=
fi
if [ "X${OPT_PC_OWNER}" != "X" ]; then
	PC_OWNER=${OPT_PC_OWNER}
else
	PC_OWNER="antpickax"
fi
if [ "X${OPT_PC_DOWNLOAD_REPO}" != "X" ]; then
	PC_DOWNLOAD_REPO=${OPT_PC_DOWNLOAD_REPO}
else
	PC_DOWNLOAD_REPO="stable"
fi

#
# Check whether to publish
#
IS_PUBLISHER=0
if [ "X${PUBLISHER}" = "Xtrue" -o "X${PUBLISHER}" = "XTRUE" -o "X${OPT_FORCE_PUBLISHER}" = "X${NODE_MAJOR_VERSION}" ]; then
	IS_PUBLISHER=1
fi

IS_TEST_PACKAGER=0
PUBLISH_REQUESTED=0
if [ ${IN_PUSH_PROCESS} -ne 1 ]; then
	#
	# Pull Request or Schedule
	#
	echo "[INFO] ${PRGNAME} : This build is run by ${GITHUB_EVENT_NAME} event, then do not test packaging."

else
	#
	# Push
	#
	IS_TEST_PACKAGER=1

	if [ "X${PUBLISH_TAG_NAME}" != "X" ]; then
		#
		# Specified Release Tag
		#
		if [ "X${NPM_TOKEN}" = "X" ]; then
			echo "[ERROR] ${PRGNAME} : Specified release tag to publish packages, but NPM token is not specified."
			exit 1
		fi
		PUBLISH_REQUESTED=1
	fi
fi

#
# Information
#
echo "[INFO] ${PRGNAME} : All local variables for building and packaging."
echo "  PRGNAME                 = ${PRGNAME}"
echo "  MYSCRIPTDIR             = ${MYSCRIPTDIR}"
echo "  SRCTOP                  = ${SRCTOP}"
echo "  NODE_MAJOR_VERSION      = ${NODE_MAJOR_VERSION}"
echo "  NODEJS_TYPE_VARS_FILE   = ${NODEJS_TYPE_VARS_FILE}"
echo "  INSTALL_PKG_LIST        = ${INSTALL_PKG_LIST}"
echo "  INSTALLER_BIN           = ${INSTALLER_BIN}"
echo "  PUBLISH_TAG_NAME        = ${PUBLISH_TAG_NAME}"
echo "  IN_PUSH_PROCESS         = ${IN_PUSH_PROCESS}"
echo "  IN_PR_PROCESS           = ${IN_PR_PROCESS}"
echo "  IN_SCHEDULE_PROCESS     = ${IN_SCHEDULE_PROCESS}"
echo "  IS_PUBLISHER            = ${IS_PUBLISHER}"
echo "  IS_TEST_PACKAGER        = ${IS_TEST_PACKAGER}"
echo "  PUBLISH_REQUESTED       = ${PUBLISH_REQUESTED}"
echo "  NPM_TOKEN               = **********"
echo "  USE_PC_REPO             = ${USE_PC_REPO}"
echo "  PC_OWNER                = ${PC_OWNER}"
echo "  PC_DOWNLOAD_REPO        = ${PC_DOWNLOAD_REPO}"

#---------------------------------------------------------------------
# Set package repository on packagecloud.io before build
#---------------------------------------------------------------------
if [ ${USE_PC_REPO} -eq 1 ]; then
	echo "[INFO] ${PRGNAME} : Setup packagecloud.io repository."

	#
	# Check curl
	#
	curl --version >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		run_cmd ${INSTALLER_BIN} update -y ${INSTALL_QUIET_ARG}
		run_cmd ${INSTALLER_BIN} install -y ${INSTALL_QUIET_ARG} curl
	fi

	#
	# Download and set packagecloud.io repository
	#
	# [NOTE]
	# The container OS must be ubuntu now.
	#
	PC_REPO_ADD_SH="script.deb.sh"
	prn_cmd "curl -s https://packagecloud.io/install/repositories/${PC_OWNER}/${PC_DOWNLOAD_REPO}/${PC_REPO_ADD_SH} | sudo bash"
	curl -s https://packagecloud.io/install/repositories/${PC_OWNER}/${PC_DOWNLOAD_REPO}/${PC_REPO_ADD_SH} | sudo bash
	if [ $? -ne 0 ]; then
		echo "[ERROR] ${PRGNAME} : could not add packagecloud.io repository."
		exit 1
	fi
fi

#---------------------------------------------------------------------
# Install packages
#---------------------------------------------------------------------
#
# Update
#
# [NOTE]
# When start to update, it may come across an unexpected interactive interface.
# (May occur with time zone updates)
# Set environment variables to avoid this.
#
export DEBIAN_FRONTEND=noninteractive 

echo "[INFO] ${PRGNAME} : Update local packages."
run_cmd sudo ${INSTALLER_BIN} update -y ${INSTALL_QUIET_ARG}

#
# Install
#
if [ "X${INSTALL_PKG_LIST}" != "X" ]; then
	echo "[INFO] ${PRGNAME} : Install packages."
	run_cmd sudo ${INSTALLER_BIN} install -y ${INSTALL_QUIET_ARG} ${INSTALL_PKG_LIST}
fi

#
# Print Node.js version
#
run_cmd node -v
run_cmd npm version

#---------------------------------------------------------------------
# Build (using /tmp directory)
#---------------------------------------------------------------------
#
# Copy sources to /tmp directory
#
echo "[INFO] ${PRGNAME} : Copy sources to /tmp directory."
run_cmd cp -rp ${SRCTOP} /tmp
TMPSRCTOP=`basename ${SRCTOP}`
BUILD_SRCTOP="/tmp/${TMPSRCTOP}"

#
# Change current directory
#
echo "[INFO] ${PRGNAME} : Change current directory to ${BUILD_SRCTOP}"
run_cmd cd ${BUILD_SRCTOP}

#
# Npm install
#
echo "[INFO] ${PRGNAME} : Run npm install."
run_cmd npm install

#
# Start build
#
echo "[INFO] ${PRGNAME} : Run npm run build."
run_cmd npm run build

#---------------------------------------------------------------------
# Start test and packaging
#---------------------------------------------------------------------
echo "[INFO] ${PRGNAME} : Start test and packaging."

if [ ${DO_NOT_RUN_TEST} -eq 1 ]; then
	echo "[INFO] ${PRGNAME} : This Node.js version(${NODE_MAJOR_VERSION}.x) is not run test and packaging."

elif [ ${IS_TEST_PACKAGER} -ne 1 ]; then
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
	if [ "X${NPM_TOKEN}" != "X" ]; then
		prn_cmd "echo \"//registry.npmjs.org/:_authToken=\${NPM_TOKEN}\" > ~/.npmrc"
		echo "//registry.npmjs.org/:_authToken=\${NPM_TOKEN}" > ~/.npmrc
		if [ $? -ne 0 ]; then
			echo "[ERROR] ${PRGNAME} : could not create .npmrc file"
			exit 1
		fi
	fi

	#
	# Modify .publishrc file if need
	#
	if [ "X${PUBLISH_TAG_NAME}" = "X" ]; then
		#
		# If not tagging, skip checking tag name
		#
		#grep -l '"uncommittedChanges": true' .publishrc | xargs sed -i.BAK -e 's/"uncommittedChanges": true/"uncommittedChanges": false/g'
		grep -l '"gitTag": true' .publishrc | xargs sed -i.BAK -e 's/"gitTag": true/"gitTag": false/g'
	fi
	if [ -f .publishrc.BAK ]; then
		rm -f .publishrc.BAK
	fi
	run_cmd cat .publishrc

	#
	# Option for publish-please command
	#
	if [ ${PUBLISH_REQUESTED} -eq 1 -a ${IS_PUBLISHER} -eq 1 ]; then
		if [ "X${NPM_TOKEN}" != "X" ]; then
			PUBLISH_PLEASE_OPT=""
		else
			echo "[WARNING] ${PRGNAME} : Required to publish, but it did not find NPM token. Therefore, it is executed by dryrun."
			exit 1
			PUBLISH_PLEASE_OPT="--dry-run"
		fi
	else
		PUBLISH_PLEASE_OPT="--dry-run"
	fi

	#
	# Publish( or test it )
	#
	run_cmd npm run publish-please ${PUBLISH_PLEASE_OPT}

	if [ ${PUBLISH_REQUESTED} -eq 1 -a ${IS_PUBLISHER} -eq 1 -a "X${NPM_TOKEN}" != "X" ]; then
		echo "[INFO] ${PRGNAME} : Succeed publishing npm package, MUST CHECK NPM repository!!"
	fi
fi

echo ""
echo "[INFO] ${PRGNAME} : Finish - Node.js version is ${NODE_MAJOR_VERSION}.x"

exit 0

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
