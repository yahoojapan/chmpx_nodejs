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
# CREATE:   Tue, Nov 24 2020
# REVISION: 1.2
#

#==============================================================
# Build helper for NodeJS on Github Actions
#==============================================================
#
# Instead of pipefail(for shells not support "set -o pipefail")
#
PIPEFAILURE_FILE="/tmp/.pipefailure.$(od -An -tu4 -N4 /dev/random | tr -d ' \n')"

#
# For shellcheck
#
if locale -a | grep -q -i '^[[:space:]]*C.utf8[[:space:]]*$'; then
	LANG=$(locale -a | grep -i '^[[:space:]]*C.utf8[[:space:]]*$' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' | tr -d '\n')
	LC_ALL="${LANG}"
	export LANG
	export LC_ALL
elif locale -a | grep -q -i '^[[:space:]]*en_US.utf8[[:space:]]*$'; then
	LANG=$(locale -a | grep -i '^[[:space:]]*en_US.utf8[[:space:]]*$' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' | tr -d '\n')
	LC_ALL="${LANG}"
	export LANG
	export LC_ALL
fi

#==============================================================
# Common variables
#==============================================================
PRGNAME=$(basename "$0")
SCRIPTDIR=$(dirname "$0")
SCRIPTDIR=$(cd "${SCRIPTDIR}" || exit 1; pwd)
SRCTOP=$(cd "${SCRIPTDIR}"/.. || exit 1; pwd)

#
# Message variables
#
IN_GHAGROUP_AREA=0

#
# Variables with default values
#
CI_NODEJS_TYPE=""
CI_NODEJS_MAJOR_VERSION=""

CI_NODEJS_TYPE_VARS_FILE="${SCRIPTDIR}/nodejstypevars.sh"
CI_USE_PACKAGECLOUD_REPO=1
CI_PACKAGECLOUD_OWNER="antpickax"
CI_PACKAGECLOUD_DOWNLOAD_REPO="stable"
CI_NPM_TOKEN=""
CI_FORCE_PUBLISHER=""

CI_IN_SCHEDULE_PROCESS=0
CI_PUBLISH_TAG_NAME=""
CI_DO_PUBLISH=0

#==============================================================
# Utility functions and variables for messaging
#==============================================================
#
# Utilities for message
#
if [ -t 1 ] || { [ -n "${CI}" ] && [ "${CI}" = "true" ]; }; then
	CBLD=$(printf '\033[1m')
	CREV=$(printf '\033[7m')
	CRED=$(printf '\033[31m')
	CYEL=$(printf '\033[33m')
	CGRN=$(printf '\033[32m')
	CDEF=$(printf '\033[0m')
else
	CBLD=""
	CREV=""
	CRED=""
	CYEL=""
	CGRN=""
	CDEF=""
fi
if [ -n "${CI}" ] && [ "${CI}" = "true" ]; then
	GHAGRP_START="::group::"
	GHAGRP_END="::endgroup::"
else
	GHAGRP_START=""
	GHAGRP_END=""
fi

PRNGROUPEND()
{
	if [ -n "${IN_GHAGROUP_AREA}" ] && [ "${IN_GHAGROUP_AREA}" -eq 1 ]; then
		if [ -n "${GHAGRP_END}" ]; then
			echo "${GHAGRP_END}"
		fi
	fi
	IN_GHAGROUP_AREA=0
}
PRNTITLE()
{
	PRNGROUPEND
	echo "${GHAGRP_START}${CBLD}${CGRN}${CREV}[TITLE]${CDEF} ${CGRN}$*${CDEF}"
	IN_GHAGROUP_AREA=1
}
PRNINFO()
{
	echo "${CBLD}${CREV}[INFO]${CDEF} $*"
}
PRNWARN()
{
	echo "${CBLD}${CYEL}${CREV}[WARNING]${CDEF} ${CYEL}$*${CDEF}"
}
PRNERR()
{
	echo "${CBLD}${CRED}${CREV}[ERROR]${CDEF} ${CRED}$*${CDEF}"
	PRNGROUPEND
}
PRNSUCCESS()
{
	echo "${CBLD}${CGRN}${CREV}[SUCCEED]${CDEF} ${CGRN}$*${CDEF}"
	PRNGROUPEND
}
PRNFAILURE()
{
	echo "${CBLD}${CRED}${CREV}[FAILURE]${CDEF} ${CRED}$*${CDEF}"
	PRNGROUPEND
}
RUNCMD()
{
	PRNINFO "Run \"$*\""
	if ! /bin/sh -c "$*"; then
		PRNERR "Failed to run \"$*\""
		return 1
	fi
	return 0
}

#----------------------------------------------------------
# Helper for NodeJS on Github Actions
#----------------------------------------------------------
func_usage()
{
	echo ""
	echo "Usage: $1 [options...]"
	echo ""
	echo "  Required option:"
	echo "    --help(-h)                                             print help"
	echo "    --nodejstype(-node)                       <version>    specify nodejs version(ex. \"18\" or \"18.x\" or \"18.0.0\")"
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
	echo "  Environments:"
	echo "    ENV_NODEJS_TYPE_VARS_FILE                 the file for custom variables                             ( same as option '--nodejstype-vars-file(-f)' )"
	echo "    ENV_NPM_TOKEN                             the token for publishing to npm                           ( same as option '--npm-token(-token)' )"
	echo "    ENV_FORCE_PUBLISHER                       nodejs major version to publish packages                  ( same as option '--force-publisher(-fp)' )"
	echo "    ENV_USE_PACKAGECLOUD_REPO                 use packagecloud.io repository: true/false                ( same as option '--use-packagecloudio-repo(-usepc)' and '--not-use-packagecloudio-repo(-notpc)' )"
	echo "    ENV_PACKAGECLOUD_OWNER                    owner name for uploading to packagecloud.io               ( same as option '--packagecloudio-owner(-pcowner)' )"
	echo "    ENV_PACKAGECLOUD_DOWNLOAD_REPO            repository name of installing packages in packagecloud.io ( same as option '--packagecloudio-download-repo(-pcdlrepo)' )"
	echo ""
	echo "  Note:"
	echo "    Environment variables and options have the same parameter items."
	echo "    If both are specified, the option takes precedence."
	echo "    Environment variables are set from Github Actions Secrets, etc."
	echo "    GITHUB_REF and GITHUB_EVENT_NAME environments are used internally."
	echo ""
}

#==============================================================
# Default execution functions and variables
#==============================================================
#
# Execution flag
#
RUN_PRE_INSTALL=0
RUN_INSTALL=1
RUN_POST_INSTALL=0
RUN_PRE_AUDIT=0
RUN_AUDIT=1
RUN_POST_AUDIT=0
RUN_CPPCHECK=1
RUN_SHELLCHECK=1
RUN_CHECK_OTHER=0
RUN_PRE_BUILD=0
RUN_BUILD=1
RUN_POST_BUILD=0
RUN_PRE_TEST=0
RUN_TEST=1
RUN_POST_TEST=0
RUN_PRE_PUBLISH=1
RUN_PUBLISH=1
RUN_POST_PUBLISH=0

#
# Before install
#
run_pre_install()
{
	PRNWARN "Not implement process before install."
	return 0
}

#
# Install
#
run_install()
{
	if ! /bin/sh -c "npm install"; then
		PRNERR "Failed to run \"npm install\"."
		return 1
	fi
	return 0
}

#
# After install
#
run_post_install()
{
	PRNWARN "Not implement process after install."
	return 0
}


#
# Before audit
#
run_pre_audit()
{
	PRNWARN "Not implement process before audit."
	return 0
}

#
# Audit
#
run_audit()
{
	if ! /bin/sh -c "npm audit"; then
		PRNERR "Failed to run \"npm audit\"."
		return 1
	fi
	return 0
}

#
# After audit
#
run_post_audit()
{
	PRNWARN "Not implement process after audit."
	return 0
}

#
# Check code by CppCheck
#
run_cppcheck()
{
	if [ -z "${CPPCHECK_TARGET}" ]; then
		PRNERR "Failed to run \"cppcheck\", target files/dirs is not specified."
		return 1
	fi

	CPPCHECK_ENABLE_OPT=""
	for _one_opt in ${CPPCHECK_ENABLE_VALUES}; do
		if [ -n "${_one_opt}" ]; then
			if [ -z "${CPPCHECK_ENABLE_OPT}" ]; then
				CPPCHECK_ENABLE_OPT="--enable="
			else
				CPPCHECK_ENABLE_OPT="${CPPCHECK_ENABLE_OPT},"
			fi
			CPPCHECK_ENABLE_OPT="${CPPCHECK_ENABLE_OPT}${_one_opt}"
		fi
	done

	CPPCHECK_IGNORE_OPT=""
	for _one_opt in ${CPPCHECK_IGNORE_VALUES}; do
		if [ -n "${_one_opt}" ]; then
			CPPCHECK_IGNORE_OPT="${CPPCHECK_IGNORE_OPT} --suppress=${_one_opt}"
		fi
	done

	CPPCHECK_BUILD_DIR_OPT=""
	if [ -n "${CPPCHECK_BUILD_DIR}" ]; then
		rm -rf "${CPPCHECK_BUILD_DIR}"
		if ! mkdir -p "${CPPCHECK_BUILD_DIR}"; then
			PRNERR "Failed to run \"cppcheck\", could not create ${CPPCHECK_BUILD_DIR} directory."
			return 1
		fi
		CPPCHECK_BUILD_DIR_OPT="--cppcheck-build-dir=${CPPCHECK_BUILD_DIR}"
	fi

	if ! /bin/sh -c "cppcheck ${CPPCHECK_BASE_OPT} ${CPPCHECK_ENABLE_OPT} ${CPPCHECK_IGNORE_OPT} ${CPPCHECK_BUILD_DIR_OPT} ${CPPCHECK_TARGET}"; then
		PRNERR "Failed to run \"cppcheck\"."
		return 1
	fi
	return 0
}

#
# Check code by ShellCheck
#
run_shellcheck()
{
	#
	# Targets
	#
	if [ -z "${SHELLCHECK_TARGET_DIRS}" ]; then
		PRNERR "Failed to run \"shellcheck\", target files/dirs is not specified."
		return 1
	fi

	#
	# Exclude options
	#
	SHELLCHECK_IGN_OPT=""
	for _one_opt in ${SHELLCHECK_IGN}; do
		if [ -n "${_one_opt}" ]; then
			if [ -z "${SHELLCHECK_IGN_OPT}" ]; then
				SHELLCHECK_IGN_OPT="--exclude="
			else
				SHELLCHECK_IGN_OPT="${SHELLCHECK_IGN_OPT},"
			fi
			SHELLCHECK_IGN_OPT="${SHELLCHECK_IGN_OPT}${_one_opt}"
		fi
	done

	SHELLCHECK_INCLUDE_IGN_OPT="${SHELLCHECK_IGN_OPT}"
	for _one_opt in ${SHELLCHECK_INCLUDE_IGN}; do
		if [ -n "${_one_opt}" ]; then
			if [ -z "${SHELLCHECK_INCLUDE_IGN_OPT}" ]; then
				SHELLCHECK_INCLUDE_IGN_OPT="--exclude="
			else
				SHELLCHECK_INCLUDE_IGN_OPT="${SHELLCHECK_INCLUDE_IGN_OPT},"
			fi
			SHELLCHECK_INCLUDE_IGN_OPT="${SHELLCHECK_INCLUDE_IGN_OPT}${_one_opt}"
		fi
	done

	#
	# Target file selection
	#
	# [NOTE]
	# SHELLCHECK_FILES_NO_SH		: Script files with file extension not ".sh" but with "#!<shell command>"
	# SHELLCHECK_FILES_SH			: Script files with file extension ".sh" and "#!<shell command>"
	# SHELLCHECK_FILES_INCLUDE_SH	: Files included in script files with file extension ".sh" but without "#!<shell command>"
	#
	SHELLCHECK_EXCEPT_PATHS_CMD="| grep -v '\.sh\.' | grep -v '\.log' | grep -v '/\.git/'"
	for _one_path in ${SHELLCHECK_EXCEPT_PATHS}; do
		SHELLCHECK_EXCEPT_PATHS_CMD="${SHELLCHECK_EXCEPT_PATHS_CMD} | grep -v '${_one_path}'"
	done

	SHELLCHECK_FILES_NO_SH="$(/bin/sh -c      "grep -ril '^\#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep -v '\.sh' ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"
	SHELLCHECK_FILES_SH="$(/bin/sh -c         "grep -ril '^\#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep '\.sh'    ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"
	SHELLCHECK_FILES_INCLUDE_SH="$(/bin/sh -c "grep -Lir '^\#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep '\.sh'    ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"

	#
	# Check scripts
	#
	_SHELLCHECK_ERROR=0
	if [ -n "${SHELLCHECK_FILES_NO_SH}" ]; then
		if ! /bin/sh -c "shellcheck ${SHELLCHECK_BASE_OPT} ${SHELLCHECK_IGN_OPT} ${SHELLCHECK_FILES_NO_SH}"; then
			_SHELLCHECK_ERROR=1
		fi
	fi
	if [ -n "${SHELLCHECK_FILES_SH}" ]; then
		if ! /bin/sh -c "shellcheck ${SHELLCHECK_BASE_OPT} ${SHELLCHECK_IGN_OPT} ${SHELLCHECK_FILES_SH}"; then
			_SHELLCHECK_ERROR=1
		fi
	fi
	if [ -n "${SHELLCHECK_FILES_INCLUDE_SH}" ]; then
		if ! /bin/sh -c "shellcheck ${SHELLCHECK_BASE_OPT} ${SHELLCHECK_INCLUDE_IGN_OPT} ${SHELLCHECK_FILES_INCLUDE_SH}"; then
			_SHELLCHECK_ERROR=1
		fi
	fi

	if [ "${_SHELLCHECK_ERROR}" -ne 0 ]; then
		PRNERR "Failed to run \"shellcheck\"."
		return 1
	fi
	return 0
}

#
# Check code by Other tools
#
run_othercheck()
{
	PRNWARN "Not implement check code by Other tools."
	return 0
}

#
# Before Build
#
run_pre_build()
{
	PRNWARN "Not implement process before building."
	return 0
}

#
# Build
#
run_build()
{
	if ! /bin/sh -c "npm run build"; then
		PRNERR "Failed to run \"npm run build\"."
		return 1
	fi
	return 0
}

#
# After Build
#
run_post_build()
{
	PRNWARN "Not implement process after building."
	return 0
}

#
# Before Test
#
run_pre_test()
{
	PRNWARN "Not implement process before testing."
	return 0
}

#
# Test
#
run_test()
{
	if ! /bin/sh -c "npm run test"; then
		PRNERR "Failed to run \"npm run test\"."
		return 1
	fi
	return 0
}

#
# After Test
#
run_post_test()
{
	PRNWARN "Not implement process after testing."
	return 0
}

#
# Before Publish
#
run_pre_publish()
{
	if [ -z "${PUBLISH_DOMAIN}" ] || [ -z "${CI_NPM_TOKEN}" ]; then
		PRNERR "PUBLISH_DOMAIN(=${PUBLISH_DOMAIN}) or CI_NPM_TOKEN(=${CI_NPM_TOKEN}) is empty."
		return 1
	fi
	export NPM_TOKEN="${CI_NPM_TOKEN}"

	if ! echo "//${PUBLISH_DOMAIN}/:_authToken=\${CI_NPM_TOKEN}" > "${HOME}"/.npmrc; then
		PRNERR "Failed to run process before publish, could not create .npmrc"
		return 1
	fi
	return 0
}

#
# Publish
#
run_publish()
{
	if ! /bin/sh -c "npm publish"; then
		PRNERR "Failed to run \"npm publish\"."
		return 1
	fi
	return 0
}

#
# After Publish
#
run_post_publish()
{
	PRNWARN "Not implement process after publish."
	return 0
}

#==============================================================
# Check options and environments
#==============================================================
PRNTITLE "Start to check options and environments"

#
# Parse options
#
OPT_NODEJS_TYPE=""
OPT_NODEJS_TYPE_VARS_FILE=""
OPT_FORCE_PUBLISHER=""
OPT_USE_PACKAGECLOUD_REPO=
OPT_PACKAGECLOUD_OWNER=""
OPT_PACKAGECLOUD_DOWNLOAD_REPO=""
OPT_NPM_TOKEN=""

while [ $# -ne 0 ]; do
	if [ -z "$1" ]; then
		break

	elif [ "$1" = "-h" ] || [ "$1" = "-H" ] || [ "$1" = "--help" ] || [ "$1" = "--HELP" ]; then
		func_usage "${PRGNAME}"
		exit 0

	elif [ "$1" = "-node" ] || [ "$1" = "-NODE" ] || [ "$1" = "--nodejstype" ] || [ "$1" = "--NODEJSTYPE" ]; then
		if [ -n "${OPT_NODEJS_TYPE}" ]; then
			PRNERR "already set \"--nodejstype(-node)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--nodejstype(-node)\" option is specified without parameter."
			exit 1
		fi
		OPT_NODEJS_TYPE="$1"

	elif [ "$1" = "-f" ] || [ "$1" = "-F" ] || [ "$1" = "--nodejstype-vars-file" ] || [ "$1" = "--NODEJSTYPE-VARS-FILE" ]; then
		if [ -n "${OPT_NODEJS_TYPE_VARS_FILE}" ]; then
			PRNERR "already set \"--nodejstype-vars-file(-f)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--nodejstype-vars-file(-f)\" option is specified without parameter."
			exit 1
		fi
		if [ ! -f "$1" ]; then
			PRNERR "$1 file is not existed, it is specified \"--ostype-vars-file(-f)\" option."
			exit 1
		fi
		OPT_NODEJS_TYPE_VARS_FILE="$1"

	elif [ "$1" = "-fp" ] || [ "$1" = "-FP" ] || [ "$1" = "--force-publisher" ] || [ "$1" = "--FORCE-PUBLISHER" ]; then
		if [ -n "${OPT_FORCE_PUBLISHER}" ]; then
			PRNERR "already set \"--force-publisher(-fp)\" or \"--not-publish(-np)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--force-publisher(-fp)\" option is specified without parameter."
			exit 1
		fi
		if echo "$1" | grep -q '[^0-9]'; then
			PRNERR "\"--force-publisher(-fp)\" option specify with Node.js major version(ex, 14/16/18...)."
			exit 1
		fi
		OPT_FORCE_PUBLISHER="$1"

	elif [ "$1" = "-usepc" ] || [ "$1" = "-USEPC" ] || [ "$1" = "--use-packagecloudio-repo" ] || [ "$1" = "--USE-PACKAGECLOUDIO-REPO" ]; then
		if [ -n "${OPT_USE_PACKAGECLOUD_REPO}" ]; then
			PRNERR "already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PACKAGECLOUD_REPO=1

	elif [ "$1" = "-notpc" ] || [ "$1" = "-NOTPC" ] || [ "$1" = "--not-use-packagecloudio-repo" ] || [ "$1" = "--NOT-USE-PACKAGECLOUDIO-REPO" ]; then
		if [ -n "${OPT_USE_PACKAGECLOUD_REPO}" ]; then
			PRNERR "already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PACKAGECLOUD_REPO=0

	elif [ "$1" = "-token" ] || [ "$1" = "-TOKEN" ] || [ "$1" = "--npm-token" ] || [ "$1" = "--NPM-TOKEN" ]; then
		if [ -n "${OPT_NPM_TOKEN}" ]; then
			PRNERR "already set \"--npm-token(-token)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--npm-token(-token)\" option is specified without parameter."
			exit 1
		fi
		OPT_NPM_TOKEN="$1"

	elif [ "$1" = "-pcowner" ] || [ "$1" = "-PCOWNER" ] || [ "$1" = "--packagecloudio-owner" ] || [ "$1" = "--PACKAGECLOUDIO-OWNER" ]; then
		if [ -n "${OPT_PACKAGECLOUD_OWNER}" ]; then
			PRNERR "already set \"--packagecloudio-owner(-pcowner)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--packagecloudio-owner(-pcowner)\" option is specified without parameter."
			exit 1
		fi
		OPT_PACKAGECLOUD_OWNER="$1"

	elif [ "$1" = "-pcdlrepo" ] || [ "$1" = "-PCDLREPO" ] || [ "$1" = "--packagecloudio-download-repo" ] || [ "$1" = "--PACKAGECLOUDIO-DOWNLOAD-REPO" ]; then
		if [ -n "${OPT_PACKAGECLOUD_DOWNLOAD_REPO}" ]; then
			PRNERR "already set \"--packagecloudio-download-repo(-pcdlrepo)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--packagecloudio-download-repo(-pcdlrepo)\" option is specified without parameter."
			exit 1
		fi
		OPT_PACKAGECLOUD_DOWNLOAD_REPO="$1"
	fi
	shift
done

#
# [Required option] check NodeJS version
#
if [ -z "${OPT_NODEJS_TYPE}" ]; then
	PRNERR "\"--nodejstype(-node)\" option is not specified."
	exit 1
else
	CI_NODEJS_TYPE="${OPT_NODEJS_TYPE}"

	CI_NODEJS_MAJOR_VERSION=$(echo "${CI_NODEJS_TYPE}" | sed -e 's/[.]/ /g' | awk '{print $1}')
	if echo "${CI_NODEJS_MAJOR_VERSION}" | grep -q '[^0-9]'; then
		PRNERR "\"NodeJS major version ${CI_NODEJS_MAJOR_VERSION}\" is wrong, it must be number(ex, 14/16/18...)."
		exit 1
	fi
	if [ "${CI_NODEJS_MAJOR_VERSION}" -le 0 ]; then
		PRNERR "\"NodeJS major version ${CI_NODEJS_MAJOR_VERSION}\" is wrong, it must be positive number(ex, 14/16/18...)."
		exit 1
	fi
fi

#
# Check other options and enviroments
#
if [ -n "${OPT_NODEJS_TYPE_VARS_FILE}" ]; then
	CI_NODEJS_TYPE_VARS_FILE="${OPT_NODEJS_TYPE_VARS_FILE}"
elif [ -n "${ENV_OSTYPE_VARS_FILE}" ]; then
	CI_NODEJS_TYPE_VARS_FILE="${ENV_NODEJS_TYPE_VARS_FILE}"
fi

if [ -n "${OPT_FORCE_PUBLISHER}" ]; then
	CI_FORCE_PUBLISHER="${OPT_FORCE_PUBLISHER}"
elif [ -n "${ENV_FORCE_PUBLISHER}" ]; then
	if echo "${ENV_FORCE_PUBLISHER}" | grep -q '[^0-9]'; then
		PRNERR "\"ENV_FORCE_PUBLISHER\" environment value must be Node.js major version(ex, 14/16/18...)."
		exit 1
	fi
	CI_FORCE_PUBLISHER="${ENV_FORCE_PUBLISHER}"
fi

if [ -n "${OPT_USE_PACKAGECLOUD_REPO}" ]; then
	if [ "${OPT_USE_PACKAGECLOUD_REPO}" -eq 1 ]; then
		CI_USE_PACKAGECLOUD_REPO=1
	elif [ "${OPT_USE_PACKAGECLOUD_REPO}" -eq 0 ]; then
		CI_USE_PACKAGECLOUD_REPO=0
	else
		PRNERR "\"OPT_USE_PACKAGECLOUD_REPO\" value is wrong."
		exit 1
	fi
elif [ -n "${ENV_USE_PACKAGECLOUD_REPO}" ]; then
	if echo "${ENV_USE_PACKAGECLOUD_REPO}" | grep -q -i '^true$'; then
		CI_USE_PACKAGECLOUD_REPO=1
	elif echo "${ENV_USE_PACKAGECLOUD_REPO}" | grep -q -i '^false$'; then
		CI_USE_PACKAGECLOUD_REPO=0
	else
		PRNERR "\"ENV_USE_PACKAGECLOUD_REPO\" value is wrong."
		exit 1
	fi
fi

if [ -n "${OPT_PACKAGECLOUD_OWNER}" ]; then
	CI_PACKAGECLOUD_OWNER="${OPT_PACKAGECLOUD_OWNER}"
elif [ -n "${ENV_PACKAGECLOUD_OWNER}" ]; then
	CI_PACKAGECLOUD_OWNER="${ENV_PACKAGECLOUD_OWNER}"
fi

if [ -n "${OPT_PACKAGECLOUD_DOWNLOAD_REPO}" ]; then
	CI_PACKAGECLOUD_DOWNLOAD_REPO="${OPT_PACKAGECLOUD_DOWNLOAD_REPO}"
elif [ -n "${ENV_PACKAGECLOUD_DOWNLOAD_REPO}" ]; then
	CI_PACKAGECLOUD_DOWNLOAD_REPO="${ENV_PACKAGECLOUD_DOWNLOAD_REPO}"
fi

if [ -n "${OPT_NPM_TOKEN}" ]; then
	CI_NPM_TOKEN="${OPT_NPM_TOKEN}"
elif [ -n "${ENV_NPM_TOKEN}" ]; then
	CI_NPM_TOKEN="${ENV_NPM_TOKEN}"
fi

# [NOTE] for ubuntu/debian
# When start to update, it may come across an unexpected interactive interface.
# (May occur with time zone updates)
# Set environment variables to avoid this.
#
export DEBIAN_FRONTEND=noninteractive

PRNSUCCESS "Start to check options and environments"

#==============================================================
# Set Variables
#==============================================================
#
# Default command parameters for each phase
#
CPPCHECK_TARGET="."
CPPCHECK_BASE_OPT="--quiet --error-exitcode=1 --inline-suppr -j 4 --std=c++03 --xml --enable=warning,style,information,missingInclude"
CPPCHECK_ENABLE_VALUES="warning style information missingInclude"
CPPCHECK_IGNORE_VALUES="unmatchedSuppression"
CPPCHECK_BUILD_DIR="/tmp/cppcheck"

SHELLCHECK_TARGET_DIRS="."
SHELLCHECK_BASE_OPT="--shell=sh"
SHELLCHECK_EXCEPT_PATHS="/node_modules/ /build/ /src/build/"
SHELLCHECK_IGN="SC1117 SC1090 SC1091"
SHELLCHECK_INCLUDE_IGN="SC2034 SC2148"

#
# Load variables from file
#
PRNTITLE "Load local variables with an external file"

#
# Load external variable file
#
if [ -f "${CI_NODEJS_TYPE_VARS_FILE}" ]; then
	PRNINFO "Load ${CI_NODEJS_TYPE_VARS_FILE} file for local variables by Node.js version(${CI_NODEJS_MAJOR_VERSION}.x)"
	. "${CI_NODEJS_TYPE_VARS_FILE}"
else
	PRNWARN "${CI_NODEJS_TYPE_VARS_FILE} file is not existed."
fi

PRNSUCCESS "Load local variables with an external file"

#----------------------------------------------------------
# Check github actions environments
#----------------------------------------------------------
PRNTITLE "Check github actions environments"

#
# GITHUB_EVENT_NAME Environment
#
if [ -n "${GITHUB_EVENT_NAME}" ] && [ "${GITHUB_EVENT_NAME}" = "schedule" ]; then
	CI_IN_SCHEDULE_PROCESS=1
else
	CI_IN_SCHEDULE_PROCESS=0
fi

#
# GITHUB_REF Environments
#
if [ -n "${GITHUB_REF}" ] && echo "${GITHUB_REF}" | grep -q 'refs/tags/'; then
	CI_PUBLISH_TAG_NAME=$(echo "${GITHUB_REF}" | sed -e 's#refs/tags/##g' | tr -d '\n')
fi

PRNSUCCESS "Check github actions environments"

#----------------------------------------------------------
# Check whether to execute processes
#----------------------------------------------------------
PRNTITLE "Check whether to execute processes"

#
# Check whether to publish
#
if [ "${IS_PUBLISHER}" -eq 1 ] || { [ -n "${CI_FORCE_PUBLISHER}" ] && [ "${CI_FORCE_PUBLISHER}" = "${CI_NODEJS_MAJOR_VERSION}" ]; }; then
	if [ -n "${CI_PUBLISH_TAG_NAME}" ]; then
		if [ -z "${CI_NPM_TOKEN}" ]; then
			PRNERR "Specified release tag for publish, but NPM token is not specified."
			exit 1
		fi
		CI_DO_PUBLISH=1
	fi
fi

PRNSUCCESS "Check whether to execute processes"

#----------------------------------------------------------
# Show execution environment variables
#----------------------------------------------------------
PRNTITLE "Show execution environment variables"

#
# Information
#
echo "  PRGNAME                       = ${PRGNAME}"
echo "  SCRIPTDIR                     = ${SCRIPTDIR}"
echo "  SRCTOP                        = ${SRCTOP}"
echo ""
echo "  CI_NODEJS_TYPE                = ${CI_NODEJS_TYPE}"
echo "  CI_NODEJS_MAJOR_VERSION       = ${CI_NODEJS_MAJOR_VERSION}"
echo "  CI_NODEJS_TYPE_VARS_FILE      = ${CI_NODEJS_TYPE_VARS_FILE}"
echo "  CI_IN_SCHEDULE_PROCESS        = ${CI_IN_SCHEDULE_PROCESS}"
echo "  CI_USE_PACKAGECLOUD_REPO      = ${CI_USE_PACKAGECLOUD_REPO}"
echo "  CI_PACKAGECLOUD_OWNER         = ${CI_PACKAGECLOUD_OWNER}"
echo "  CI_PACKAGECLOUD_DOWNLOAD_REPO = ${CI_PACKAGECLOUD_DOWNLOAD_REPO}"
echo "  CI_NPM_TOKEN                  = **********"
echo "  CI_FORCE_PUBLISHER            = ${CI_FORCE_PUBLISHER}"
echo "  CI_PUBLISH_TAG_NAME           = ${CI_PUBLISH_TAG_NAME}"
echo "  CI_DO_PUBLISH                 = ${CI_DO_PUBLISH}"
echo ""
echo "  INSTALL_PKG_LIST              = ${INSTALL_PKG_LIST}"
echo "  INSTALLER_BIN                 = ${INSTALLER_BIN}"
echo "  PUBLISH_DOMAIN                = ${PUBLISH_DOMAIN}"
echo "  IS_PUBLISHER                  = ${IS_PUBLISHER}"
echo ""

PRNSUCCESS "Show execution environment variables"

#==============================================================
# Install all packages
#==============================================================
PRNTITLE "Update repository and Install curl"

#
# Update local packages
#
PRNINFO "Update local packages"
if ({ RUNCMD sudo "${INSTALLER_BIN}" update -y "${INSTALL_QUIET_ARG}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to update local packages"
	exit 1
fi

#
# Check and install curl
#
if ! CURLCMD=$(command -v curl); then
	PRNINFO "Install curl command"
	if ({ RUNCMD sudo "${INSTALLER_BIN}" install -y "${INSTALL_QUIET_ARG}" curl || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install curl command"
		exit 1
	fi
	if ! CURLCMD=$(command -v curl); then
		PRNERR "Not found curl command"
		exit 1
	fi
else
	PRNINFO "Already curl is insatlled."
fi
PRNSUCCESS "Update repository and Install curl"

#--------------------------------------------------------------
# Set package repository for packagecloud.io
#--------------------------------------------------------------
PRNTITLE "Set package repository for packagecloud.io"

if [ "${CI_USE_PACKAGECLOUD_REPO}" -eq 1 ]; then
	#
	# Setup packagecloud.io repository
	#
	# [NOTE]
	# The container OS must be ubuntu now.
	#
	PRNINFO "Download script and setup packagecloud.io reposiory"
	PC_REPO_ADD_SH="script.deb.sh"
	if ({ RUNCMD "${CURLCMD} -s https://packagecloud.io/install/repositories/${CI_PACKAGECLOUD_OWNER}/${CI_PACKAGECLOUD_DOWNLOAD_REPO}/${PC_REPO_ADD_SH} | sudo bash" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to download script or setup packagecloud.io reposiory"
		exit 1
	fi
else
	PRNINFO "Not set packagecloud.io repository."
fi
PRNSUCCESS "Set package repository for packagecloud.io"

#--------------------------------------------------------------
# Install packages
#--------------------------------------------------------------
PRNTITLE "Install packages for building/packaging"

if [ -n "${INSTALL_PKG_LIST}" ]; then
	PRNINFO "Install packages"
	if ({ RUNCMD sudo "${INSTALLER_BIN}" install -y "${INSTALL_QUIET_ARG}" "${INSTALL_PKG_LIST}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install packages"
		exit 1
	fi
else
	PRNINFO "Specified no packages for installing. "
fi

PRNSUCCESS "Install packages for building/packaging"

#--------------------------------------------------------------
# Install cppcheck
#--------------------------------------------------------------
PRNTITLE "Install cppcheck"

if [ "${RUN_CPPCHECK}" -eq 1 ]; then
	PRNINFO "Install cppcheck package."

	# [NOTE]
	# The container OS must be ubuntu now.
	#
	if ({ RUNCMD sudo "${INSTALLER_BIN}" install -y cppcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install cppcheck"
		exit 1
	fi
else
	PRNINFO "Skip to install cppcheck package, because cppcheck process does not need."
fi
PRNSUCCESS "Install cppcheck"

#--------------------------------------------------------------
# Install shellcheck
#--------------------------------------------------------------
PRNTITLE "Install shellcheck"

if [ "${RUN_SHELLCHECK}" -eq 1 ]; then
	PRNINFO "Install shellcheck package."

	# [NOTE]
	# The container OS must be ubuntu now.
	#
	if ({ RUNCMD sudo "${INSTALLER_BIN}" install -y shellcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install cppcheck"
		exit 1
	fi
else
	PRNINFO "Skip to install shellcheck package, because shellcheck process does not need."
fi
PRNSUCCESS "Install shellcheck"

#--------------------------------------------------------------
# Print information about NodeJS
#--------------------------------------------------------------
PRNTITLE "Print information about NodeJS"

PRNINFO "NodeJS Version"
if ({ RUNCMD node -v || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to print NodeJS Version"
	exit 1
fi

PRNINFO "NPM Version"
if ({ RUNCMD npm version || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to print NPM Version"
	exit 1
fi

PRNSUCCESS "Print information about NodeJS"

#==============================================================
# Processing
#==============================================================
#
# Change current directory
#
PRNTITLE "Change current directory"

if ! RUNCMD cd "${SRCTOP}"; then
	PRNERR "Failed to chnage current directory to ${SRCTOP}"
	exit 1
fi

PRNSUCCESS "Changed current directory"

#--------------------------------------------------------------
# Install NodeJS packages
#--------------------------------------------------------------
#
# Before install
#
if [ "${RUN_PRE_INSTALL}" -eq 1 ]; then
	PRNTITLE "Before install"
	if ({ run_pre_install 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Before install\"."
		exit 1
	fi
	PRNSUCCESS "Before install."
fi

#
# Install
#
if [ "${RUN_INSTALL}" -eq 1 ]; then
	PRNTITLE "Install"
	if ({ run_install 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Install\"."
		exit 1
	fi
	PRNSUCCESS "Install."
fi

#
# After install
#
if [ "${RUN_POST_INSTALL}" -eq 1 ]; then
	PRNTITLE "After install"
	if ({ run_post_install 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Before install\"."
		exit 1
	fi
	PRNSUCCESS "Before install."
fi

#--------------------------------------------------------------
# Audit
#--------------------------------------------------------------
#
# Before Audit
#
if [ "${RUN_PRE_AUDIT}" -eq 1 ]; then
	PRNTITLE "Before Audit"
	if ({ run_pre_audit 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Before Audit\"."
		exit 1
	fi
	PRNSUCCESS "Before Audit."
fi

#
# Audit
#
if [ "${RUN_AUDIT}" -eq 1 ]; then
	PRNTITLE "Audit"
	if ({ run_audit 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Audit\"."
		exit 1
	fi
	PRNSUCCESS "Audit."
fi

#
# After Audit
#
if [ "${RUN_POST_AUDIT}" -eq 1 ]; then
	PRNTITLE "After Audit"
	if ({ run_post_audit 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"After Audit\"."
		exit 1
	fi
	PRNSUCCESS "After Audit."
fi

#--------------------------------------------------------------
# Check code
#--------------------------------------------------------------
#
# CppCheck
#
if [ "${RUN_CPPCHECK}" -eq 1 ]; then
	PRNTITLE "Check code by CppCheck"
	if ({ run_cppcheck 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Check code by CppCheck\"."
		exit 1
	fi
	PRNSUCCESS "Check code by CppCheck."
fi

#
# ShellCheck
#
if [ "${RUN_SHELLCHECK}" -eq 1 ]; then
	PRNTITLE "Check code by ShellCheck"
	if ({ run_shellcheck 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Check code by ShellCheck\"."
		exit 1
	fi
	PRNSUCCESS "Check code by ShellCheck."
fi

#
# Other tools
#
if [ "${RUN_CHECK_OTHER}" -eq 1 ]; then
	PRNTITLE "Check code by Other tools"
	if ({ run_othercheck 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Check code by Other tools\"."
		exit 1
	fi
	PRNSUCCESS "Check code by Other tools."
fi

#--------------------------------------------------------------
# Build
#--------------------------------------------------------------
#
# Before Build
#
if [ "${RUN_PRE_BUILD}" -eq 1 ]; then
	PRNTITLE "Before Build"
	if ({ run_pre_build 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Before Build\"."
		exit 1
	fi
	PRNSUCCESS "Before Build."
fi

#
# Build
#
if [ "${RUN_BUILD}" -eq 1 ]; then
	PRNTITLE "Build"
	if ({ run_build 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Build\"."
		exit 1
	fi
	PRNSUCCESS "Build."
fi

#
# After Build
#
if [ "${RUN_POST_BUILD}" -eq 1 ]; then
	PRNTITLE "After Build"
	if ({ run_post_build 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"After Build\"."
		exit 1
	fi
	PRNSUCCESS "After Build."
fi

#--------------------------------------------------------------
# Test
#--------------------------------------------------------------
#
# Before Test
#
if [ "${RUN_PRE_TEST}" -eq 1 ]; then
	PRNTITLE "Before Test"
	if ({ run_pre_test 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Before Test\"."
		exit 1
	fi
	PRNSUCCESS "Before Test."
fi

#
# Test
#
if [ "${RUN_TEST}" -eq 1 ]; then
	PRNTITLE "Test"
	if ({ run_test 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"Test\"."
		exit 1
	fi
	PRNSUCCESS "Test."
fi

#
# After Test
#
if [ "${RUN_POST_TEST}" -eq 1 ]; then
	PRNTITLE "After Test"
	if ({ run_post_test 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNFAILURE "Failed \"After Test\"."
		exit 1
	fi
	PRNSUCCESS "After Test."
fi

#--------------------------------------------------------------
# Publish
#--------------------------------------------------------------
if [ "${CI_DO_PUBLISH}" -eq 1 ]; then
	#
	# Before Publish
	#
	if [ "${RUN_PRE_PUBLISH}" -eq 1 ]; then
		PRNTITLE "Before Publish"
		if ({ run_pre_publish 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNFAILURE "Failed \"Before Publish\"."
			exit 1
		fi
		PRNSUCCESS "Before Publish."
	fi

	#
	# Publish
	#
	if [ "${RUN_PUBLISH}" -eq 1 ]; then
		PRNTITLE "Publish"
		if ({ run_publish 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNFAILURE "Failed \"Publish\"."
			exit 1
		fi
		PRNSUCCESS "Published, MUST CHECK NPM repository!."
	fi

	#
	# After Publish
	#
	if [ "${RUN_POST_PUBLISH}" -eq 1 ]; then
		PRNTITLE "After Publish"
		if ({ run_post_publish 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNFAILURE "Failed \"After Publish\"."
			exit 1
		fi
		PRNSUCCESS "After Publish."
	fi
else
	PRNTITLE "Publish processing"
	PRNSUCCESS "This CI process does not publish package."
fi

#----------------------------------------------------------
# Finish
#----------------------------------------------------------
PRNSUCCESS "Finished all processing without error."

exit 0

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
