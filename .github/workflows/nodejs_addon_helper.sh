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
# REVISION: 1.5
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
if command -v locale >/dev/null 2>&1; then
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
fi

#==============================================================
# Common variables
#==============================================================
PRGNAME=$(basename "$0")
SCRIPTDIR=$(dirname "$0")
SCRIPTDIR=$(cd "${SCRIPTDIR}" || exit 1; pwd)
SRCTOP=$(cd "${SCRIPTDIR}"/../.. || exit 1; pwd)

#
# Message variables
#
IN_GHAGROUP_AREA=0

#
# Variables with default values
#
CI_OSTYPE=""
CI_NODEJS_TYPE=""
CI_NODEJS_MAJOR_VERSION=""

CI_GITHUB_TOKEN=""
CI_NODEJS_TYPE_VARS_FILE="${SCRIPTDIR}/nodejstypevars.sh"
CI_USE_PACKAGECLOUD_REPO=1
CI_PACKAGECLOUD_OWNER="antpickax"
CI_PACKAGECLOUD_DOWNLOAD_REPO="stable"
CI_NPM_OIDC_AUDIENCE=""
CI_NPM_OIDC_EXCHANGE_URL=""
CI_FORCE_PUBLISHER=""
CI_FORCE_NOT_PUBLISHER=0

CI_IN_SCHEDULE_PROCESS=0
CI_PUBLISH_TAG_NAME=""
CI_DO_BINARY_PUBLISH=0
CI_DO_NPM_PUBLISH=0

PATH_PACKAGE_JSON="${SRCTOP}/package.json"

#
# Function result value
#
FOUND_VALUE_IN_JSON=""

#==============================================================
# Utility functions and variables for messaging
#==============================================================
#
# Utilities for message
#
if [ -t 1 ] || { [ -n "${CI}" ] && [ "${CI}" = "true" ]; }; then
#	CBLD=$(printf '\033[1m')
#	CREV=$(printf '\033[7m')
	CRED=$(printf '\033[31m')
	CYEL=$(printf '\033[33m')
	CGRN=$(printf '\033[32m')
	CDEF=$(printf '\033[0m')
else
#	CBLD=""
#	CREV=""
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
	echo "${GHAGRP_START}${CGRN}[TITLE]${CDEF} ${CGRN}$*${CDEF}"
	IN_GHAGROUP_AREA=1
}
PRNINFO()
{
	echo "[INFO]${CDEF} $*"
}
PRNWARN()
{
	echo "${CYEL}[WARNING]${CDEF} ${CYEL}$*${CDEF}"
}
PRNERR()
{
	echo "${CRED}[ERROR]${CDEF} ${CRED}$*${CDEF}"
	PRNGROUPEND
}
PRNSUCCESS()
{
	echo "${CGRN}[SUCCEED]${CDEF} ${CGRN}$*${CDEF}"
	echo ""
	PRNGROUPEND
}
PRNFAILURE()
{
	echo "${CRED}[FAILURE]${CDEF} ${CRED}$*${CDEF}"
	echo ""
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
# Utility for get value in json file
#----------------------------------------------------------
# Input:
#	$1	file path
#	$2	depth level
#	$3	key name
# Output:
#	FOUND_VALUE_IN_JSON
#
get_value_from_json_file()
{
	#
	# Clear
	#
	FOUND_VALUE_IN_JSON=""

	if [ $# -ne 3 ]; then
		return 1
	fi
	if [ ! -f "$1" ]; then
		return 1
	fi
	_TARGET_JSON_FILE="$1"
	if echo "$2" | grep -q '[^0-9]'; then
		return 1
	fi
	_TARGET_DEPTH="$2"
	_TARGET_KEYNAME="$3"

	_NEST_DEPTH=0
	while IFS= read -r _ONE_LINE || [ -n "${_ONE_LINE}" ]; do
		#
		# Get "{" and "}" count in one line
		#
		_OPEN_COUNT_IN_LINE=$(printf '%s' "${_ONE_LINE}" | tr -cd '{' | wc -c | tr -d '[:space:]')
		_CLOSE_COUNT_IN_LINE=$(printf '%s' "${_ONE_LINE}" | tr -cd '}' | wc -c | tr -d '[:space:]')
		if [ -z "$_OPEN_COUNT_IN_LINE" ]; then
			_OPEN_COUNT_IN_LINE=0
		fi
		if [ -z "$_CLOSE_COUNT_IN_LINE" ]; then
			_CLOSE_COUNT_IN_LINE=0
		fi

		#
		# Current nest count(depth)
		#
		_NEST_DEPTH=$((_NEST_DEPTH + _OPEN_COUNT_IN_LINE - _CLOSE_COUNT_IN_LINE))

		#
		# Check depth
		#
		if [ "$_NEST_DEPTH" -eq "${_TARGET_DEPTH}" ]; then
			#
			# Check key name
			#
			if echo "${_ONE_LINE}" | grep -q "^[[:space:]]*\"${_TARGET_KEYNAME}\"[[:space:]]*:"; then
				#
				# Found and get value
				#
				FOUND_VALUE_IN_JSON=$(echo "${_ONE_LINE}" | sed -e "s#^[[:space:]]*\"${_TARGET_KEYNAME}\"[[:space:]]*:[[:space:]]*##" -e 's#[",]##g' -e 's#^[[:space:]]*##' -e 's#[[:space:]]*$##' | tr -d '\n')
				return 0
			fi
		fi
	done < "${_TARGET_JSON_FILE}"

	#
	# Not found
	#
	return 1
}

#----------------------------------------------------------
# Utility: Upload binary package files to asset
#----------------------------------------------------------
#	$1	Prepository <owner/repository> (= GITHUB_REPOSITORY or "git remote get-url origin", etc)
#	$2	Release tag (= GITHUB_REF or "refs/tags", etc)
#	$3	Package directory path (= <SRCTOP>/prebuilds or <SRCTOP>/prebuilds/<scope>)
#	$4	Github token (= GITHUB_TOKEN)
#
upload_asset()
{

	if [ $# -ne 4 ]; then
		PRNERR "Internal error: parameters are wrong."
		return 1
	fi
	_UPLOAD_REPO="$1"
	_UPLOAD_REPO_OWNER="$(echo "${_UPLOAD_REPO}" | cut -d'/' -f1)"
	_UPLOAD_REPO_NAME="$(echo "${_UPLOAD_REPO}" | cut -d'/' -f2)"
	_UPLOAD_TAG="$2"
	_PKG_DIRECTORY="$3"
	_UPLOAD_TOKEN="$4"
	_UPLAD_AUTH_HEADER="Authorization: token ${_UPLOAD_TOKEN}"

	_UPLOAD_API_URL="https://api.github.com"
	if [ -n "${GITHUB_API_URL}" ]; then
		_UPLOAD_API_URL="${GITHUB_API_URL}"
	fi
	_RELASE_JSON_TMPFILE="/tmp/${PRGNAME}.$$.release.json"

	#
	# Check Release tag and get release.json file
	#
	# ex)	{
	#		    "url": "https://api.github.com/repos/<owner>/<repo>/releases/<release id>",
	#		    "assets_url": "https://api.github.com/repos/<owner>/<repo>/releases/<release id>/assets",
	#		    "upload_url": "https://uploads.github.com/repos/<owner>/<repo>/releases/<release id>/assets{?name,label}",
	#		    "html_url": "https://github.com/<owner>/<repo>/releases/tag/v1.1.34",
	#		    "id": <release id>,
	#		    "author": { ...
	#		    },
	#		    ...
	#		}
	#
	if ! _RESULT_CODE=$("${CURLCMD}" -s -S -w '%{http_code}' -o "${_RELASE_JSON_TMPFILE}" -X GET "${_UPLOAD_API_URL}/repos/${_UPLOAD_REPO_OWNER}/${_UPLOAD_REPO_NAME}/releases/tags/${_UPLOAD_TAG}" --insecure); then
		PRNERR "Not found ${_UPLOAD_TAG} release tag."
		rm -f "${_RELASE_JSON_TMPFILE}"
		return 1
	fi
	if [ -z "${_RESULT_CODE}" ] || [ "${_RESULT_CODE}" -ne 200 ]; then
		PRNERR "Not found ${_UPLOAD_TAG} release tag(http status code: (${_RESULT_CODE})."
		rm -f "${_RELASE_JSON_TMPFILE}"
		return 1
	fi
	if [ ! -f "${_RELASE_JSON_TMPFILE}" ]; then
		PRNERR "Not found ${_RELASE_JSON_TMPFILE} release.json file."
		return 1
	fi

	#
	# Get Upload URL
	#
	if ! get_value_from_json_file "${_RELASE_JSON_TMPFILE}" 1 "upload_url" || [ -z "${FOUND_VALUE_IN_JSON}" ]; then
		PRNERR "Could not get \"upload_url\" from ${_RELASE_JSON_TMPFILE} release.json file."
		rm -f "${_RELASE_JSON_TMPFILE}"
		return 1
	fi
	_UPLOAD_URL_TEMPL="${FOUND_VALUE_IN_JSON}"
	rm -f "${_RELASE_JSON_TMPFILE}"

	# [NOTE]
	# Convert URL
	#	from: "https://uploads.github.com/repos/<owner>/<repo>/releases/<release id>/assets{?name,label}"
	#           v
	#	to:   "https://uploads.github.com/repos/<owner>/<repo>/releases/<release id>/assets"
	#
	_UPLOAD_URL_TEMPL=$(echo "${_UPLOAD_URL_TEMPL}" | sed -e 's#[\{].*[\}]$##' | tr -d '\n')

	#
	# Upload files
	#
	# [NOTE]
	# If an asset with the same name already exists, the upload will fail.
	# The existing file will not be deleted and not be overwritten.
	#
	for _ONE_PKG_FILE_PATH in "${_PKG_DIRECTORY}"/*; do
		if [ ! -f "${_ONE_PKG_FILE_PATH}" ]; then
			PRNWARN "Not found ${_ONE_PKG_FILE_PATH} file."
			continue
		fi
		if ! _ONE_PKG_FILE=$(basename "${_ONE_PKG_FILE_PATH}" | tr -d '\n'); then
			PRNWARN "Something error occured during convert filename(${_ONE_PKG_FILE_PATH})."
			continue
		fi
		#
		# Urlencode
		#
		if ! _ENCODED_ONE_PKG_FILE=$(printf '%s' "${_ONE_PKG_FILE}" | od -An -tu1 -v | tr -s ' ' '\n' | sed '/^$/d' | awk '{ code=$1; if ((code>=48 && code<=57) || (code>=65 && code<=90) || (code>=97 && code<=122) || code==45 || code==46 || code==95 || code==126){ printf "%c", code; }else{ printf "%%%02X", code; } } END{ printf "\n"; }'); then
			PRNWARN "Something error occured during convert filename(${_ONE_PKG_FILE_PATH})."
			continue
		fi

		#
		# Content type
		#
		if echo "_ONE_PKG_FILE" | grep -q -e '.tar.gz$' -e '.tgz$'; then
			_FILE_CONTENT_TYPE="application/gzip"
		elif echo "_ONE_PKG_FILE" | grep -q '.zip$'; then
			_FILE_CONTENT_TYPE="application/zip"
		elif echo "_ONE_PKG_FILE" | grep -q -e '.sha256$' -e '.txt$'; then
			_FILE_CONTENT_TYPE="text/plain"
		elif echo "_ONE_PKG_FILE" | grep -q '.json$'; then
			_FILE_CONTENT_TYPE="application/json"
		else
			_FILE_CONTENT_TYPE="application/octet-stream"
		fi

		#
		# Do upload
		#
		if ! "${CURLCMD}" -s -S -f -H "${_UPLAD_AUTH_HEADER}" -H "Content-Type: ${_FILE_CONTENT_TYPE}" --data-binary @"${_ONE_PKG_FILE_PATH}" "${_UPLOAD_URL_TEMPL}?name=${_ENCODED_ONE_PKG_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to upload ${_ONE_PKG_FILE} file into asset."
			return 1
		fi
		PRNINFO "Succeed to upload ${_ONE_PKG_FILE} file into asset."
	done

	return 0
}

#----------------------------------------------------------
# Utility for modify package.json file for npm package
#----------------------------------------------------------
#
# Modify package.json file
#
# In case do not include binary data in NPM package, remove
# the "prebuilds" and "build/Release/*.node" entries from the
# "files" section of "package.json". A backup of the original
# "package.json" will be created as "package.json.org".
# This backup file will be used to restore using the restore
# function.
#
#	$1	Path for package.json file
#
# [NOTE]
# This function works assuming the "files" section of the
# package.json file is in the following format (pay attention
# to line breaks, etc.).
# It will not work correctly if this is not the case.
#	--------------------------------------
#	"files": [
#		"index.js",
#		"index.mjs",
#		"binding.gyp",
#		"types",
#		"src",
#		"build/cjs/index.js",
#		"build/esm/index.js",
#		"build/Assets/*.tar.gz",
#		"buildutils/make_node_prebuild_variables.sh",
#		"buildutils/node_prebuild_install.sh",
#		"buildutils/node_prebuild.sh",
#		"README.md",
#		"LICENSE"
#	],
#	--------------------------------------
#	- The files section is defined as an array of "[...]"
#	- Each element is on a separate line.
#
remove_binaries_from_pacakage_json()
{
	if [ $# -ne 1 ]; then
		return 1
	fi
	if [ ! -f "$1" ]; then
		return 1
	fi
	_PACKAGE_JSON_FILE="$1"

	_BACKUP_PACKAGE_JSON_FILE="${_PACKAGE_JSON_FILE}.org"
	if [ -f "${_BACKUP_PACKAGE_JSON_FILE}" ]; then
		PRNWARN "The backup file(${_BACKUP_PACKAGE_JSON_FILE}) for package.json file(_PACKAGE_JSON_FILE) is existed, so overwrite it."
		rm -f "${_BACKUP_PACKAGE_JSON_FILE}" 2>/dev/null
	fi
	if ! mv "${_PACKAGE_JSON_FILE}" "${_BACKUP_PACKAGE_JSON_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to carete the backup file(${_BACKUP_PACKAGE_JSON_FILE}) for package.json file(_PACKAGE_JSON_FILE)."
		return 1
	fi

	_KW_TGZ_FILE='"build/Assets/\*.tar.gz"'
	_IN_FILES_SECTION=0
	while IFS= read -r _ONE_LINE || [ -n "${_ONE_LINE}" ]; do
		if [ "${_IN_FILES_SECTION}" -eq 0 ]; then
			if printf '%s' "${_ONE_LINE}" | grep -q '^[[:space:]]*[,]*[[:space:]]*"files"[[:space:]]*[:]*[[:space:]]*'; then
				_IN_FILES_SECTION=1
			fi
			printf '%s\n' "${_ONE_LINE}"
		else
			if printf '%s' "${_ONE_LINE}" | grep -q '^[[:space:]]*\][[:space:]]*'; then
				_IN_FILES_SECTION=0
				printf '%s\n' "${_ONE_LINE}"
			elif printf '%s' "${_ONE_LINE}" | grep -q "[[:space:]]*${_KW_TGZ_FILE}[[:space:]]*"; then
				# found, nothing to print
				:
			else
				printf '%s\n' "${_ONE_LINE}"
			fi
		fi
	done < "${_BACKUP_PACKAGE_JSON_FILE}" > "${_PACKAGE_JSON_FILE}"

	return 0
}

#
# Restore package.json file
#
#	$1	Path for package.json file
#
restore_pacakage_json()
{
	if [ $# -ne 1 ]; then
		return 1
	fi
	_PACKAGE_JSON_FILE="$1"

	_BACKUP_PACKAGE_JSON_FILE="${_PACKAGE_JSON_FILE}.org"
	if [ ! -f "${_BACKUP_PACKAGE_JSON_FILE}" ]; then
		PRNERR "The backup file(${_BACKUP_PACKAGE_JSON_FILE}) is not existed."
		return 1
	fi
	if [ -f "${_PACKAGE_JSON_FILE}" ]; then
		rm -f "${_PACKAGE_JSON_FILE}" 2>/dev/null
	fi
	if ! mv "${_BACKUP_PACKAGE_JSON_FILE}" "${_PACKAGE_JSON_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to rename the backup file(${_BACKUP_PACKAGE_JSON_FILE}) to package.json file(_PACKAGE_JSON_FILE)."
		return 1
	fi
	return 0
}

#----------------------------------------------------------
# Make sure the repository is original (not forked)
#----------------------------------------------------------
# Environments:
#	GITHUB_EVENT_PATH	The path to the file on the runner that
#						contains the full event webhook payload
#
is_current_repo_original()
{
	if [ -z "${GITHUB_EVENT_PATH}" ] || [ ! -f "${GITHUB_EVENT_PATH}" ]; then
		return 1
	fi

	#
	# Convert multiple line to single line
	#
	_FILTER_RESULT=$(tr -d '\n' < "${GITHUB_EVENT_PATH}" 2>/dev/null)

	#
	# Check "repository" key
	#
	if ! echo "${_FILTER_RESULT}" | grep -q '^.*\"repository\"[[:space:]]*:[[:space:]]*'; then
		return 1
	fi
	_FILTER_RESULT=$(echo "${_FILTER_RESULT}" | sed -e 's#^.*\"repository\"[[:space:]]*:[[:space:]]*##g')

	#
	# Check "fork" key (in "repository" value)
	#
	if ! echo "${_FILTER_RESULT}" | grep -q '^.*\"fork\"[[:space:]]*:[[:space:]]*'; then
		return 1
	fi

	#
	# Get "fork" value
	#
	# [NOTE]
	# The "repository" object must have a "fork" key.
	#
	_FILTER_RESULT=$(echo "${_FILTER_RESULT}" | sed -e 's#^.*\"fork\"[[:space:]]*:[[:space:]]*##g' -e 's#\}.*##g' -e 's#\].*##g' -e 's#[[:space:]]*$##g')

	if echo "${_FILTER_RESULT}" | grep -q -i 'false'; then
		return 0
	fi
	return 1
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
	echo "    --ostype(-os)                             <os:version> specify os and version as like \"ubuntu:jammy\""
	echo "    --nodejstype(-node)                       <version>    specify nodejs version(ex. \"18\" or \"18.x\" or \"18.0.0\")"
	echo ""
	echo "  Option:"
	echo "    --nodejstype-vars-file(-f)                <file path>  specify the file that describes the package list to be installed before build(default is nodejstypevars.sh)"
	echo "    --oidc-audience(-oa)                      <string>     OIDC Audience for automation NPM token(ex. npm)"
	echo "    --oidc-exchange-url(-oeu)                 <URL>        OIDC exchange URL for automation NPM token(ex. https://registry.npmjs.org/-/v1/oidc/exchange)"
	echo "    --force-publisher(-fp)                    <os>/<node>  specify publisher OS type and node major version(ex. ubuntu:24.04/24 or ubuntu:noble/22)."
	echo "    --force-not-publisher(-np)                             do not allow to publish any packages."
	echo ""
	echo "  Option for packagecloud.io:"
	echo "    --use-packagecloudio-repo(-usepc)                      use packagecloud.io repository(default), exclusive -notpc option"
	echo "    --not-use-packagecloudio-repo(-notpc)                  not use packagecloud.io repository, exclusive -usepc option"
	echo "    --packagecloudio-owner(-pcowner)          <owner>      owner name of uploading destination to packagecloud.io, this is part of the repository path(default is antpickax)"
	echo "    --packagecloudio-download-repo(-pcdlrepo) <repository> repository name of installing packages in packagecloud.io, this is part of the repository path(default is stable)"
	echo ""
	echo "  Environments:"
	echo "    ENV_GITHUB_TOKEN                          token for github"
	echo "    ENV_NODEJS_TYPE_VARS_FILE                 the file for custom variables                             ( same as option '--nodejstype-vars-file(-f)' )"
	echo "    ENV_NPM_OIDC_AUDIENCE                     OIDC Audience for automation NPM token                    ( same as option '--oidc-audience(-oa)' )"
	echo "    ENV_NPM_OIDC_EXCHANGE_URL                 OIDC exchange URL for automation NPM token                ( same as option '--oidc-exchange-url(-oeu)' )"
	echo "    ENV_FORCE_PUBLISHER                       nodejs major version to publish packages                  ( same as option '--force-publisher(-fp)' )"
	echo "    ENV_FORCE_NOT_PUBLISHER                   do not allow to publish any packages                      ( same as option '--force-not-publisher(-np)' )"
	echo "    ENV_USE_PACKAGECLOUD_REPO                 use packagecloud.io repository: true/false                ( same as option '--use-packagecloudio-repo(-usepc)' and '--not-use-packagecloudio-repo(-notpc)' )"
	echo "    ENV_PACKAGECLOUD_OWNER                    owner name for uploading to packagecloud.io               ( same as option '--packagecloudio-owner(-pcowner)' )"
	echo "    ENV_PACKAGECLOUD_DOWNLOAD_REPO            repository name of installing packages in packagecloud.io ( same as option '--packagecloudio-download-repo(-pcdlrepo)' )"
	echo "    ENV_NPM_TOKEN                             [Deprecated] currently use automation NPM token."
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
RUN_PRE_TEST=1
RUN_TEST=1
RUN_POST_TEST=0
RUN_PRE_PUBLISH=1
RUN_PUBLISH=1
RUN_POST_PUBLISH=1

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
	#
	# Skip check binary and build locally
	#
	if ! /bin/sh -c "ANTPICKAX_SKIP_PREBUILD_INSTALL=true npm install"; then
		PRNERR "Failed to run \"npm install\"."
		return 1
	fi
	PRNINFO "Finished to run \"npm install\"."

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
	PRNINFO "Finished to run \"npm audit\"."

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
	PRNINFO "Finished to run \"cppcheck\"."

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
	SHELLCHECK_EXCEPT_PATHS_CMD="| grep -v '\.log' | grep -v '/\.git/'"
	for _one_path in ${SHELLCHECK_EXCEPT_PATHS}; do
		SHELLCHECK_EXCEPT_PATHS_CMD="${SHELLCHECK_EXCEPT_PATHS_CMD} | grep -v '${_one_path}'"
	done

	SHELLCHECK_FILES_NO_SH="$(/bin/sh -c      "grep -ril '^#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep -v '\.sh' ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"
	SHELLCHECK_FILES_SH="$(/bin/sh -c         "grep -ril '^#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep '\.sh'    ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"
	SHELLCHECK_FILES_INCLUDE_SH="$(/bin/sh -c "grep -Lir '^#!/bin/sh' ${SHELLCHECK_TARGET_DIRS} | grep '\.sh'    ${SHELLCHECK_EXCEPT_PATHS_CMD} | tr '\n' ' '")"

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
	PRNINFO "Finished to run \"shellcheck\"."

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
	if [ -n "${IS_TEST_CJS}" ] && [ "${IS_TEST_CJS}" -eq 1 ]; then
		# [NOTE]
		# When running tests in NodeJS 20(and some OSes) with TypeScript, Mocha
		# will throw the error ERR_REQUIRE_CYCLE_MODULE.
		# Currently, there is no workaround, so you will need to convert the test
		# scripts to CommonJS beforehand and run them as CommonJS.
		# Note that TypeScript tests are run in other NodeJS versions, so there
		# is no problem.
		#
		if ! /bin/sh -c "npm run build:ts:tests:cjs"; then
			PRNERR "Failed to run \"npm run build:ts:tests:cjs\"."
			return 1
		fi
		PRNINFO "Finished to run \"npm run build:ts:tests:cjs\"."
	else
		PRNINFO "Not implement process before testing."
	fi
	return 0
}

#
# Test
#
run_test()
{
	if [ -n "${IS_TEST_CJS}" ] && [ "${IS_TEST_CJS}" -eq 1 ]; then
		TEST_SCRIPTTYPE="commonjs"
	else
		TEST_SCRIPTTYPE="typescript"
	fi

	if ! /bin/sh -c "TEST_SCRIPTTYPE=${TEST_SCRIPTTYPE} npm run test"; then
		PRNERR "Failed to run \"npm run test\"."
		return 1
	fi
	PRNINFO "Finished to run \"npm run test\"."
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
	# [NOTE]
	# For NodeJS addons, builds are performed using npm install or prebuild.
	# Here, we run prebuild, then rebuild and create a binary package.
	#
	if ! /bin/sh -c "npm run build:prebuild"; then
		PRNERR "Failed to run \"npm run build:prebuild\"."
		return 1
	fi

	#
	# Setup NPM TOKEN and .npmrc(only old method type)
	#
	if [ "${CI_DO_NPM_PUBLISH}" -eq 1 ]; then
		# [NOTE]
		# Currently, we use "NPM Trusted publishing".
		# (You need to configure Trusted publishing for each package on the NPM site.)
		# Keep to support the old method,  if GitHub Actions Secret.NPM_TOKEN value
		# is set, we use it.
		#
		if [ -n "${ENV_NPM_TOKEN}" ]; then
			#
			# Set NPM token for old method type
			#
			# [Deprecated]
			# This is left in for debugging purposes only, but the NPM configuration is
			# configured to reject no OIDC tokens, so it should not be used normally.
			#
			export NODE_AUTH_TOKEN="${ENV_NPM_TOKEN}"

			#
			# Setup .npmrc file
			#
			if ! echo "https://${PUBLISH_DOMAIN}/" > "${HOME}"/.npmrc; then
				PRNERR "Failed to run process before publish, could not set domain to .npmrc"
				return 1
			fi
			if ! echo "//${PUBLISH_DOMAIN}/:_authToken=${NODE_AUTH_TOKEN}" >> "${HOME}"/.npmrc; then
				PRNERR "Failed to run process before publish, could not set token to .npmrc"
				return 1
			fi
			PRNINFO "Finished to set NPM_TOKEN and create .npmrc(as old publishing type)."
		else
			PRNINFO "Using NPM trusted publishing, so nothing to set NPM_TOKEN and .npmrc"
		fi
	fi

	#
	# Modify package.json
	#
	if [ "${CI_DO_BINARY_PUBLISH}" -eq 1 ]; then
		if ! remove_binaries_from_pacakage_json "${PATH_PACKAGE_JSON}"; then
			PRNERR "Failed to modify package.json file for removing binary entries in files section."
			return 1
		fi
		PRNINFO "Finished to modify package.json for removing binary entries."
	fi

	#
	# Build npm package
	#
	if ! /bin/sh -c "npm pack"; then
		PRNERR "Failed to run \"npm pack\"."
		return 1
	fi
	PRNINFO "Finished to run \"npm pack\"."

	return 0
}

#
# Publish
#
run_publish()
{
	#
	# Forked repository is not publish 
	#
	_IS_ORIGINAL_REPOSITORY=0
	if is_current_repo_original; then
		_IS_ORIGINAL_REPOSITORY=1
	fi

	#
	# Publish binary package(to github.com asset)
	#
	if [ "${CI_DO_BINARY_PUBLISH}" -eq 1 ]; then
		#
		# Get Repository(<owner>/<repo>) and prebuilds directory path
		#
		_UPLOAD_REPOSITORY="${GITHUB_REPOSITORY}"
		if [ -z "${_UPLOAD_REPOSITORY}" ]; then
			if ! _UPLOAD_REPOSITORY=$(git remote get-url origin 2>/dev/null | awk -F'[:/]' '{n=NF; print $(n-1)"/"$n}' | sed 's#\.git$##'); then
				PRNERR "Could not get <owner>/<repo> for uploading files to asset."
				return 1
			fi
			if [ -z "${_UPLOAD_REPOSITORY}" ]; then
				PRNERR "Could not get <owner>/<repo> for uploading files to asset."
				return 1
			fi
		fi
		_BINARY_PKG_DIR_PATH=$(buildutils/make_node_prebuild_variables.sh --output-dirname)

		#
		# Upload
		#
		if [ "${_IS_ORIGINAL_REPOSITORY}" -eq 1 ]; then
			if ! upload_asset "${_UPLOAD_REPOSITORY}" "${CI_PUBLISH_TAG_NAME}" "${_BINARY_PKG_DIR_PATH}" "${CI_GITHUB_TOKEN}"; then
				return 1
			fi
			PRNINFO "Finished to upload binaries to github.com assets."
		else
			PRNINFO "Assets upload skipped because this repository is forked."
		fi
	else
		PRNINFO "No binaries upload to github.com assets."
	fi

	#
	# Publish NPM package
	#
	if [ "${CI_DO_NPM_PUBLISH}" -eq 1 ]; then
		if [ "${_IS_ORIGINAL_REPOSITORY}" -eq 1 ]; then
			#
			# Run publish
			#
			if [ -n "${ENV_NPM_TOKEN}" ]; then
				if ! /bin/sh -c "npm publish"; then
					PRNERR "Failed to run \"npm publish\"."
					return 1
				fi
			else
				# [NOTE]
				# Always specify "--provenance" and "--access public" (for first uploading)
				#
				if ! /bin/sh -c "npm publish --provenance --access public"; then
					PRNERR "Failed to run \"npm publish\"."
					return 1
				fi
			fi
			PRNINFO "Finished to run \"npm publish\"."
		else
			PRNINFO "\"npm publish\" skipped because this repository is forked."
		fi
	else
		PRNINFO "Nothing to publish NPM package."
	fi
	return 0
}

#
# After Publish
#
run_post_publish()
{
	#
	# Restore package.json
	#
	if [ "${CI_DO_BINARY_PUBLISH}" -eq 1 ]; then
		if ! restore_pacakage_json "${PATH_PACKAGE_JSON}"; then
			PRNERR "Failed to restore package.json file."
			return 1
		fi
		PRNINFO "Finished to restore original package.json."
	fi

	#
	# Remove .npmrc file
	#
	if [ -f "${HOME}"/.npmrc ]; then
		rm -f "${HOME}"/.npmrc 2>/dev/null
	fi
	PRNINFO "Finished to remove .npmrc file."

	return 0
}

#==============================================================
# Check options and environments
#==============================================================
PRNTITLE "Start to check options and environments"

#
# Parse options
#
OPT_OSTYPE=""
OPT_NODEJS_TYPE=""
OPT_NODEJS_TYPE_VARS_FILE=""
OPT_FORCE_NOT_PUBLISHER=0
OPT_USE_PACKAGECLOUD_REPO=
OPT_PACKAGECLOUD_OWNER=""
OPT_PACKAGECLOUD_DOWNLOAD_REPO=""
OPT_NPM_OIDC_AUDIENCE=""
OPT_NPM_OIDC_EXCHANGE_URL=""

while [ $# -ne 0 ]; do
	if [ -z "$1" ]; then
		break

	elif echo "$1" | grep -q -i -e "^-h$" -e "^--help$"; then
		func_usage "${PRGNAME}"
		exit 0

	elif echo "$1" | grep -q -i -e "^-os$" -e "^--ostype$"; then
		if [ -n "${OPT_OSTYPE}" ]; then
			PRNERR "already set \"--ostype(-os)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--ostype(-os)\" option is specified without parameter."
			exit 1
		fi
		OPT_OSTYPE="$1"

	elif echo "$1" | grep -q -i -e "^-node$" -e "^--nodejstype$"; then
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

	elif echo "$1" | grep -q -i -e "^-f$" -e "^--nodejstype-vars-file$"; then
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

	elif echo "$1" | grep -q -i -e "^-fp$" -e "^--force-publisher$"; then
		if [ -n "${OPT_FORCE_PUBLISHER}" ]; then
			PRNERR "already set \"--force-publisher(-fp)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--force-publisher(-fp)\" option is specified without parameter."
			exit 1
		fi
		if ! echo "$1" | grep -q '/'; then
			PRNERR "\"--force-publisher(-fp)\" option value is specified without parameter."
			exit 1
		fi
		_TMP_OS_PART=$(echo "$1" | awk -F'/' '{print $1}')
		_TMP_NODE_PART=$(echo "$1" | awk -F'/' '{print $2}')
		if [ -z "${_TMP_OS_PART}" ] || [ -z "${_TMP_NODE_PART}" ] || echo "${_TMP_NODE_PART}" | grep -q '[^0-9]'; then
			PRNERR "Specify the value of the \"--force-publisher(-fp)\" option in \"<OS type>/<Node major version>\"."
			exit 1
		fi
		OPT_FORCE_PUBLISHER="$1"

	elif echo "$1" | grep -q -i -e "^-np$" -e "^--force-not-publisher$"; then
		if [ "${OPT_FORCE_NOT_PUBLISHER}" -ne 0 ]; then
			PRNERR "already set \"--force-not-publisher(-np)\" option."
			exit 1
		fi
		OPT_FORCE_NOT_PUBLISHER="$1"

	elif echo "$1" | grep -q -i -e "^-usepc$" -e "^--use-packagecloudio-repo$"; then
		if [ -n "${OPT_USE_PACKAGECLOUD_REPO}" ]; then
			PRNERR "already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PACKAGECLOUD_REPO=1

	elif echo "$1" | grep -q -i -e "^-notpc$" -e "^--not-use-packagecloudio-repo$"; then
		if [ -n "${OPT_USE_PACKAGECLOUD_REPO}" ]; then
			PRNERR "already set \"--use-packagecloudio-repo(-usepc)\" or \"--not-use-packagecloudio-repo(-notpc)\" option."
			exit 1
		fi
		OPT_USE_PACKAGECLOUD_REPO=0

	elif echo "$1" | grep -q -i -e "^-oa$" -e "^--oidc-audience$"; then
		if [ -n "${OPT_NPM_OIDC_AUDIENCE}" ]; then
			PRNERR "already set \"--oidc-audience(-oa)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--oidc-audience(-oa)\" option is specified without parameter."
			exit 1
		fi
		OPT_NPM_OIDC_AUDIENCE="$1"

	elif echo "$1" | grep -q -i -e "^-oeu$" -e "^--oidc-exchange-url$"; then
		if [ -n "${OPT_NPM_OIDC_EXCHANGE_URL}" ]; then
			PRNERR "already set \"--oidc-exchange-url(-oeu)\" option."
			exit 1
		fi
		shift
		if [ $# -eq 0 ]; then
			PRNERR "\"--oidc-exchange-url(-oeu)\" option is specified without parameter."
			exit 1
		fi
		OPT_NPM_OIDC_EXCHANGE_URL="$1"

	elif echo "$1" | grep -q -i -e "^-pcowner$" -e "^--packagecloudio-owner$"; then
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

	elif echo "$1" | grep -q -i -e "^-pcdlrepo$" -e "^--packagecloudio-download-repo$"; then
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
# [Required option] check OS and version
#
if [ -z "${OPT_OSTYPE}" ]; then
	PRNERR "\"--ostype(-os)\" option is not specified."
	exit 1
else
	CI_OSTYPE="${OPT_OSTYPE}"
fi

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
if [ -n "${ENV_GITHUB_TOKEN}" ]; then
	CI_GITHUB_TOKEN="${ENV_GITHUB_TOKEN}"
fi

if [ -n "${OPT_NODEJS_TYPE_VARS_FILE}" ]; then
	CI_NODEJS_TYPE_VARS_FILE="${OPT_NODEJS_TYPE_VARS_FILE}"
elif [ -n "${ENV_OSTYPE_VARS_FILE}" ]; then
	CI_NODEJS_TYPE_VARS_FILE="${ENV_NODEJS_TYPE_VARS_FILE}"
fi

if [ -n "${OPT_FORCE_PUBLISHER}" ]; then
	CI_FORCE_PUBLISHER="${OPT_FORCE_PUBLISHER}"
elif [ -n "${ENV_FORCE_PUBLISHER}" ]; then
	_TMP_OS_PART=$(echo "${ENV_FORCE_PUBLISHER}" | awk -F'/' '{print $1}')
	_TMP_NODE_PART=$(echo "${ENV_FORCE_PUBLISHER}" | awk -F'/' '{print $2}')
	if [ -z "${_TMP_OS_PART}" ] || [ -z "${_TMP_NODE_PART}" ] || echo "${_TMP_NODE_PART}" | grep -q '[^0-9]'; then
		PRNERR "Specify the value of the \"ENV_FORCE_PUBLISHER\" environment in \"<OS type>/<Node major version>\"."
		exit 1
	fi
	CI_FORCE_PUBLISHER="${ENV_FORCE_PUBLISHER}"
fi

if [ "${OPT_FORCE_NOT_PUBLISHER}" -ne 0 ]; then
	CI_FORCE_NOT_PUBLISHER=1
elif [ -n "${ENV_FORCE_NOT_PUBLISHER}" ]; then
	if [ "${ENV_FORCE_NOT_PUBLISHER}" = "true" ] || [ "${ENV_FORCE_NOT_PUBLISHER}" -eq 1 ]; then
		CI_FORCE_NOT_PUBLISHER=1
	fi
fi

if [ -n "${CI_FORCE_PUBLISHER}" ] && [ "${CI_FORCE_NOT_PUBLISHER}" -ne 0 ]; then
	PRNERR "\"FORCE_PUBLISHER\"(ENV or --force-publisher(-fp) option) and \"FORCE_NOT_PUBLISHER\"(ENV or --force-not-publisher(-np) option) cannot be specified together."
	exit 1
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

if [ -n "${OPT_NPM_OIDC_AUDIENCE}" ]; then
	CI_NPM_OIDC_AUDIENCE="${OPT_NPM_OIDC_AUDIENCE}"
elif [ -n "${ENV_NPM_OIDC_AUDIENCE}" ]; then
	CI_NPM_OIDC_AUDIENCE="${ENV_NPM_OIDC_AUDIENCE}"
fi

if [ -n "${OPT_NPM_OIDC_EXCHANGE_URL}" ]; then
	CI_NPM_OIDC_EXCHANGE_URL="${OPT_NPM_OIDC_EXCHANGE_URL}"
elif [ -n "${ENV_NPM_OIDC_EXCHANGE_URL}" ]; then
	CI_NPM_OIDC_EXCHANGE_URL="${ENV_NPM_OIDC_EXCHANGE_URL}"
fi

#
# Check running as root user
#
RUN_USER_ID=$(id -u)
if [ -n "${RUN_USER_ID}" ] && [ "${RUN_USER_ID}" -eq 0 ]; then
	SUDO_CMD=""
else
	SUDO_CMD="sudo"
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
CPPCHECK_BASE_OPT="--quiet --error-exitcode=1 --inline-suppr -j 8 --std=c++17 --xml --enable=warning,style,information,missingInclude"
CPPCHECK_ENABLE_VALUES="warning style information missingInclude"
CPPCHECK_IGNORE_VALUES="unmatchedSuppression missingIncludeSystem normalCheckLevelMaxBranches"
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

if [ -n "${NOT_PROVIDED_NODEVER}" ] && [ "${NOT_PROVIDED_NODEVER}" -eq 1 ]; then
	#
	# Not provided this combination of OS and NodeJS.
	#
	# [NOTE]
	# Exit this script here with SUCCESS status.
	#
	PRNSUCCESS "Load local variables with an external file"

	PRNINFO "This OS and NodeJS combination is not provided, so stop all processing with success status."

	PRNSUCCESS "Finished all processing without error(not provoded this OS and NodeJS combination)."
	exit 0
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
if [ "${CI_FORCE_NOT_PUBLISHER}" -eq 0 ]; then
	if [ -n "${CI_PUBLISH_TAG_NAME}" ]; then
		#
		# Set binary packages publishing
		#
		CI_DO_BINARY_PUBLISH=1

		#
		# Check force publisher
		#
		if [ -n "${CI_FORCE_PUBLISHER}" ]; then
			if [ "${CI_FORCE_PUBLISHER}" = "${CI_NODEJS_MAJOR_VERSION}" ]; then
				IS_NPM_PUBLISHER=1
			else
				IS_NPM_PUBLISHER=0
			fi
		fi
		if [ "${IS_NPM_PUBLISHER}" -eq 1 ]; then
			if [ -z "${CI_NPM_OIDC_AUDIENCE}" ] && [ -z "${CI_NPM_OIDC_EXCHANGE_URL}" ] && [ -z "${ENV_NPM_TOKEN}" ]; then
				PRNWARN "Specified release tag for publish, but OIDC audience and URL is empty and NPM token specified directly is empty. Then will fail to publish."
			fi
			if [ -z "${PUBLISH_DOMAIN}" ]; then
				PRNWARN "Specified release tag for publish, but publish domain name is not specified. Then will fail to publish."
			fi
			CI_DO_NPM_PUBLISH=1
		fi
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
echo "  CI_OSTYPE                     = ${CI_OSTYPE}"
echo "  CI_NODEJS_TYPE                = ${CI_NODEJS_TYPE}"
echo "  CI_NODEJS_MAJOR_VERSION       = ${CI_NODEJS_MAJOR_VERSION}"
echo "  CI_NODEJS_TYPE_VARS_FILE      = ${CI_NODEJS_TYPE_VARS_FILE}"
echo "  CI_IN_SCHEDULE_PROCESS        = ${CI_IN_SCHEDULE_PROCESS}"
echo "  CI_USE_PACKAGECLOUD_REPO      = ${CI_USE_PACKAGECLOUD_REPO}"
echo "  CI_PACKAGECLOUD_OWNER         = ${CI_PACKAGECLOUD_OWNER}"
echo "  CI_PACKAGECLOUD_DOWNLOAD_REPO = ${CI_PACKAGECLOUD_DOWNLOAD_REPO}"

if [ -n "${CI_GITHUB_TOKEN}" ]; then
	echo "  CI_GITHUB_TOKEN               = **********"
else
	echo "  CI_GITHUB_TOKEN               = (empty)"
fi
if [ -n "${CI_NPM_OIDC_AUDIENCE}" ]; then
	echo "  CI_NPM_OIDC_AUDIENCE          = **********"
else
	echo "  CI_NPM_OIDC_AUDIENCE          = (empty)"
fi
if [ -n "${CI_NPM_OIDC_EXCHANGE_URL}" ]; then
	echo "  CI_NPM_OIDC_EXCHANGE_URL      = **********"
else
	echo "  CI_NPM_OIDC_EXCHANGE_URL      = (empty)"
fi
if [ -n "${ENV_NPM_TOKEN}" ]; then
	echo "  ENV_NPM_TOKEN(deprecated)     = **********"
else
	echo "  ENV_NPM_TOKEN(deprecated)     = (empty)"
fi

echo "  CI_FORCE_PUBLISHER            = ${CI_FORCE_PUBLISHER}"
echo "  CI_FORCE_NOT_PUBLISHER        = ${CI_FORCE_NOT_PUBLISHER}"
echo "  CI_PUBLISH_TAG_NAME           = ${CI_PUBLISH_TAG_NAME}"
echo "  CI_DO_BINARY_PUBLISH          = ${CI_DO_BINARY_PUBLISH}"
echo "  CI_DO_NPM_PUBLISH             = ${CI_DO_NPM_PUBLISH}"
echo ""
echo "  INSTALLER_BIN                 = ${INSTALLER_BIN}"
echo "  UPDATE_CMD                    = ${UPDATE_CMD}"
echo "  UPDATE_CMD_ARG                = ${UPDATE_CMD_ARG}"
echo "  INSTALL_CMD                   = ${INSTALL_CMD}"
echo "  INSTALL_CMD_ARG               = ${INSTALL_CMD_ARG}"
echo "  INSTALL_AUTO_ARG              = ${INSTALL_AUTO_ARG}"
echo "  INSTALL_QUIET_ARG             = ${INSTALL_QUIET_ARG}"
echo "  INSTALL_PKG_LIST              = ${INSTALL_PKG_LIST}"
echo ""
echo "  IS_OS_UBUNTU                  = ${IS_OS_UBUNTU}"
echo "  IS_OS_DEBIAN                  = ${IS_OS_DEBIAN}"
echo "  IS_OS_FEDORA                  = ${IS_OS_FEDORA}"
echo "  IS_OS_ROCKY                   = ${IS_OS_ROCKY}"
echo "  IS_OS_ALPINE                  = ${IS_OS_ALPINE}"
echo ""
echo "  CPPCHECK_TARGET               = ${CPPCHECK_TARGET}"
echo "  CPPCHECK_BASE_OPT             = ${CPPCHECK_BASE_OPT}"
echo "  CPPCHECK_ENABLE_VALUES        = ${CPPCHECK_ENABLE_VALUES}"
echo "  CPPCHECK_IGNORE_VALUES        = ${CPPCHECK_IGNORE_VALUES}"
echo "  CPPCHECK_BUILD_DIR            = ${CPPCHECK_BUILD_DIR}"
echo ""
echo "  SHELLCHECK_TARGET_DIRS        = ${SHELLCHECK_TARGET_DIRS}"
echo "  SHELLCHECK_BASE_OPT           = ${SHELLCHECK_BASE_OPT}"
echo "  SHELLCHECK_EXCEPT_PATHS       = ${SHELLCHECK_EXCEPT_PATHS}"
echo "  SHELLCHECK_IGN                = ${SHELLCHECK_IGN}"
echo "  SHELLCHECK_INCLUDE_IGN        = ${SHELLCHECK_INCLUDE_IGN}"
echo ""
echo "  PUBLISH_DOMAIN                = ${PUBLISH_DOMAIN}"
echo "  IS_NPM_PUBLISHER              = ${IS_NPM_PUBLISHER}"
echo "  IS_TEST_CJS                   = ${IS_TEST_CJS}"
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
if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${UPDATE_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to update local packages"
	exit 1
fi

#
# Check and install curl
#
if ! CURLCMD=$(command -v curl); then
	PRNINFO "Install curl command"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" curl || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
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
	if [ "${IS_OS_FEDORA}" -eq 1 ] || [ "${IS_OS_ROCKY}" -eq 1 ]; then
		PC_REPO_ADD_SH="script.rpm.sh"
		PC_REPO_ADD_SH_RUN="bash"
	elif [ "${IS_OS_UBUNTU}" -eq 1 ] || [ "${IS_OS_DEBIAN}" -eq 1 ]; then
		PC_REPO_ADD_SH="script.deb.sh"
		PC_REPO_ADD_SH_RUN="bash"
	elif [ "${IS_OS_ALPINE}" -eq 1 ]; then
		PC_REPO_ADD_SH="script.alpine.sh"
		PC_REPO_ADD_SH_RUN="sh"
	else
		PC_REPO_ADD_SH=""
		PC_REPO_ADD_SH_RUN=""
	fi
	if [ -n "${PC_REPO_ADD_SH}" ]; then
		PRNINFO "Download script and setup packagecloud.io reposiory"
		if ({ RUNCMD "${CURLCMD} -s https://packagecloud.io/install/repositories/${CI_PACKAGECLOUD_OWNER}/${CI_PACKAGECLOUD_DOWNLOAD_REPO}/${PC_REPO_ADD_SH} | ${SUDO_CMD} ${PC_REPO_ADD_SH_RUN}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to download script or setup packagecloud.io reposiory"
			exit 1
		fi
	else
		PRNWARN "OS is not debian/ubuntu nor fedora/rocky nor alpine, then we do not know which download script use. Thus skip to setup packagecloud.io repository."
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

	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" "${INSTALL_PKG_LIST}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install packages"
		exit 1
	fi
else
	PRNINFO "Specified no packages for installing. "
fi

PRNSUCCESS "Install packages for building/packaging"

#--------------------------------------------------------------
# Install NodeJS
#--------------------------------------------------------------
# [NOTE]
# NodeJS should be installed by "actions/setup-node@v4" in ci.yml,
# but this is not currently supported on some operating systems.
# Installation is not supported on Alpine. Also, on RockyLinux:10,
# the PATH environment variable is set improperly and will not work.
# Therefore, this script manually installs NodeJS and prepares
# the environment.
#
PRNTITLE "Install NodeJS"

if [ "${IS_OS_FEDORA}" -eq 1 ] || [ "${IS_OS_ROCKY}" -eq 1 ]; then
	#
	# Fedora / Rocky
	#
	NODEJS_SETUP_URL="https://rpm.nodesource.com/setup_${CI_NODEJS_MAJOR_VERSION}.x"

	PRNINFO "Update local packages before install NodeJS(${CI_NODEJS_MAJOR_VERSION})"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${UPDATE_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to update local packages before install NodeJS(${CI_NODEJS_MAJOR_VERSION})"
		exit 1
	fi

	PRNINFO "Download setup NodeJS(${CI_NODEJS_MAJOR_VERSION}) script and run it"
	if ({ /bin/sh -c "${CURLCMD} -fsSL ${NODEJS_SETUP_URL} 2>/dev/null | ${SUDO_CMD} /bin/bash - 2>&1" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to download setup NodeJS(${CI_NODEJS_MAJOR_VERSION}) script and run it."
		exit 1
	fi

	PRNINFO "Install NodeJS(${CI_NODEJS_MAJOR_VERSION}) and etc"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" "${NODEJS_PKG_LIST}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install NodeJS(${CI_NODEJS_MAJOR_VERSION}), etc."
		exit 1
	fi

elif [ "${IS_OS_UBUNTU}" -eq 1 ] || [ "${IS_OS_DEBIAN}" -eq 1 ]; then
	#
	# Ubuntu / Debian
	#
	NODEJS_KEYRING_DIR="/etc/apt/keyrings"
	NODEJS_REPO_GPGKEY_FILE="${NODEJS_KEYRING_DIR}/nodesource.gpg"
	NODEJS_REPO_GPGKEY_URL="https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"
	NODEJS_SOURCELIST_FILE="/etc/apt/sources.list.d/nodesource.list"
	NODEJS_SETUP_URL="https://deb.nodesource.com/node_${CI_NODEJS_MAJOR_VERSION}.x"

	PRNINFO "Try to create ${NODEJS_KEYRING_DIR} directory"
	if ({ RUNCMD "${SUDO_CMD}" mkdir -p "${NODEJS_KEYRING_DIR}" 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to create ${NODEJS_KEYRING_DIR} directory"
		exit 1
	fi

	PRNINFO "Download NodeJS GPG Key and setup it"
	if [ -f "${NODEJS_REPO_GPGKEY_FILE}" ]; then
		if ({ RUNCMD "${SUDO_CMD}" rm -f "${NODEJS_REPO_GPGKEY_FILE}" 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to remove existed ${NODEJS_REPO_GPGKEY_FILE} file."
			exit 1
		fi
	fi
	if ({ /bin/sh -c "${CURLCMD} -fsSL ${NODEJS_REPO_GPGKEY_URL} 2>/dev/null | ${SUDO_CMD} gpg --dearmor -o ${NODEJS_REPO_GPGKEY_FILE} 2>&1" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to download NodeJS GPG Key and setup it."
		exit 1
	fi

	PRNINFO "Setup apt source list for NodeJS(${CI_NODEJS_MAJOR_VERSION})"
	if ({ /bin/sh -c "echo 'deb [signed-by=${NODEJS_REPO_GPGKEY_FILE}] ${NODEJS_SETUP_URL} nodistro main' | ${SUDO_CMD} tee ${NODEJS_SOURCELIST_FILE} 2>&1" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to setup apt source list for NodeJS(${CI_NODEJS_MAJOR_VERSION})."
		exit 1
	fi

	PRNINFO "Update local packages before install NodeJS"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${UPDATE_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to update local packages before install NodeJS"
		exit 1
	fi

	PRNINFO "Install NodeJS(${CI_NODEJS_MAJOR_VERSION}) and etc"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" "${NODEJS_PKG_LIST}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install NodeJS(${CI_NODEJS_MAJOR_VERSION}), etc."
		exit 1
	fi

elif [ "${IS_OS_ALPINE}" -eq 1 ]; then
	#
	# Alpine
	#
	PRNINFO "Update local packages before install NodeJS"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${UPDATE_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to update local packages before install NodeJS"
		exit 1
	fi

	PRNINFO "Install NodeJS(${CI_NODEJS_MAJOR_VERSION}) and etc"
	if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" "${INSTALL_QUIET_ARG}" "${NODEJS_PKG_LIST}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
		PRNERR "Failed to install NodeJS(${CI_NODEJS_MAJOR_VERSION}), etc"
		exit 1
	fi

else
	PRNINFO "Skip to install NodeJS package, because OS type is unknown."
fi

PRNSUCCESS "Install NodeJS"

#--------------------------------------------------------------
# Install cppcheck
#--------------------------------------------------------------
PRNTITLE "Install cppcheck"

if [ "${RUN_CPPCHECK}" -eq 1 ]; then
	PRNINFO "Install cppcheck package."

	if [ "${IS_OS_FEDORA}" -eq 1 ]; then
		#
		# Fedora
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" cppcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install cppcheck"
			exit 1
		fi

	elif [ "${IS_OS_ROCKY}" -eq 1 ]; then
		if echo "${CI_OSTYPE}" | sed -e 's#:##g' | grep -q -i 'rockylinux8'; then
			#
			# Rocky 8
			#
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to install epel repository"
				exit 1
			fi
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" config-manager --enable epel || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to enable epel repository"
				exit 1
			fi
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" config-manager --set-enabled powertools || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to enable powertools"
				exit 1
			fi
		elif echo "${CI_OSTYPE}" | sed -e 's#:##g' | grep -q -i 'rockylinux9'; then
			#
			# Rocky 9
			#
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to install epel repository"
				exit 1
			fi
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" config-manager --enable epel || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to enable epel repository"
				exit 1
			fi
		else
			#
			# Rocky 10 or later
			#
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to install epel repository"
				exit 1
			fi
			if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" config-manager --enable epel || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
				PRNERR "Failed to enable epel repository"
				exit 1
			fi
		fi
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" cppcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install cppcheck"
			exit 1
		fi

	elif [ "${IS_OS_UBUNTU}" -eq 1 ] || [ "${IS_OS_DEBIAN}" -eq 1 ]; then
		#
		# Ubuntu or Debian
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" cppcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install cppcheck"
			exit 1
		fi

	elif [ "${IS_OS_ALPINE}" -eq 1 ]; then
		#
		# Alpine
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" cppcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install cppcheck"
			exit 1
		fi

	else
		PRNINFO "Skip to install cppcheck package, because unknown to install it."
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

	if [ "${IS_OS_FEDORA}" -eq 1 ]; then
		#
		# Fedora
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" ShellCheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install shellcheck"
			exit 1
		fi

	elif [ "${IS_OS_ROCKY}" -eq 1 ]; then
		#
		# Rocky
		#
		if ! LATEST_SHELLCHECK_DOWNLOAD_URL=$("${CURLCMD}" -s -S https://api.github.com/repos/koalaman/shellcheck/releases/latest | tr ',' '\n' | grep '"browser_download_url"' | grep 'linux.x86_64' | grep 'tar.xz'| sed -e 's#"browser_download_url"[[:space:]]*:##g' -e 's#{##g' -e 's#}##g' -e 's#\[##g' -e 's#\]##g' -e 's#,##g' -e 's#"##g' -e 's#[[:space:]]##g' | head -1 | tr -d '\n'); then
			PRNERR "Failed to get shellcheck download url path"
			exit 1
		fi
		if ({ RUNCMD "${CURLCMD}" -s -S -L -o /tmp/shellcheck.tar.xz "${LATEST_SHELLCHECK_DOWNLOAD_URL}" || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to download latest shellcheck tar.xz"
			exit 1
		fi
		if ({ RUNCMD "${SUDO_CMD}" tar -C /usr/bin/ -xf /tmp/shellcheck.tar.xz --no-anchored 'shellcheck' --strip=1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to extract latest shellcheck binary"
			exit 1
		fi
		rm -f /tmp/shellcheck.tar.xz

	elif [ "${IS_OS_UBUNTU}" -eq 1 ] || [ "${IS_OS_DEBIAN}" -eq 1 ]; then
		#
		# Ubuntu or Debian
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" shellcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install shellcheck"
			exit 1
		fi

	elif [ "${IS_OS_ALPINE}" -eq 1 ]; then
		#
		# Alpine
		#
		if ({ RUNCMD "${SUDO_CMD}" "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_CMD_ARG}" "${INSTALL_AUTO_ARG}" shellcheck || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's/^/    /g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
			PRNERR "Failed to install shellcheck"
			exit 1
		fi

	else
		PRNINFO "Skip to install shellcheck package, because unknown to install it."
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
