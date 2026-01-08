#!/bin/sh
#
# Utility helper tools for Github Actions by AntPickax
#
# Copyright 2025 Yahoo Japan Corporation.
#
# AntPickax provides utility tools for supporting nodejs addon.
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
# CREATE:   Wed 19 Nov 2025
# REVISION:
#

#==============================================================
# Node Prebuild Warpper
#==============================================================
#
# Instead of pipefail(for shells not support "set -o pipefail")
#
#PIPEFAILURE_FILE="/tmp/.pipefailure.$(od -An -tu4 -N4 /dev/random | tr -d ' \n')"

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
# Variables
#==============================================================
#PRGNAME=$(basename "$0")
SCRIPTDIR=$(dirname "$0")
SCRIPTDIR=$(cd "${SCRIPTDIR}" || exit 1; pwd)
SRCTOP=$(cd "${SCRIPTDIR}"/.. || exit 1; pwd)

#
# Common variables
#
MAKE_VARS_FILE="make_node_prebuild_variables.sh"
MAKE_VARS_BIN="${SCRIPTDIR}/${MAKE_VARS_FILE}"
META_JSON_FILE="metadata.json"

#
# Variables
#
ASSET_TGZ_FILENAME=$("${MAKE_VARS_BIN}" --tgz-filename)
ASSET_SHA256_FILENAME=$("${MAKE_VARS_BIN}" --sha256-filename)
ASSET_TGZ_DOWNLOAD_URL=$("${MAKE_VARS_BIN}" --tgz-download-url)
ASSET_SHA256_DOWNLOAD_URL=$("${MAKE_VARS_BIN}" --sha256-download-url)

#==============================================================
# Utility functions and variables for messaging
#==============================================================
#
# Utilities for message
#
if [ -t 1 ] || { [ -n "${CI}" ] && [ "${CI}" = "true" ]; }; then
#	CBLD=$(printf '\033[1m')
#	CREV=$(printf '\033[7m')
#	CRED=$(printf '\033[31m')
#	CYEL=$(printf '\033[33m')
	CGRN=$(printf '\033[32m')
	CDEF=$(printf '\033[0m')
else
#	CBLD=""
#	CREV=""
#	CRED=""
#	CYEL=""
	CGRN=""
	CDEF=""
fi

PRNTITLE()
{
	echo ""
	echo "${CGRN}[TITLE]${CDEF} ${CGRN}$*${CDEF}"
}

PRNINFO()
{
	echo "[INFO] $*"
}

PRNSUCCESS()
{
	echo ""
	echo "${CGRN}[SUCCEED]${CDEF} ${CGRN}$*${CDEF}"
	echo ""
}

#==============================================================
# Utility functons
#==============================================================
#
# Check binary tgz file in local and Setup it
#
check_and_setup_local_asset_file()
{
	if [ ! -f "${SRCTOP}/build/Assets/${ASSET_TGZ_FILENAME}" ]; then
		PRNINFO "Not found ${ASSET_TGZ_FILENAME} in build/Assets directory."
		return 1
	fi

	#
	# Exract file from tgz file
	#
	_CUR_DIR=$(pwd)
	cd "${SRCTOP}" || exit 1
	if ! tar xvfz "${SRCTOP}/build/Assets/${ASSET_TGZ_FILENAME}" >/dev/null 2>&1; then
		PRNINFO "Could not extract files from ${ASSET_TGZ_FILENAME} file."
		cd "${_CUR_DIR}" || exit 1
		return 1
	fi
	cd "${_CUR_DIR}" || exit 1

	#
	# metadata.json file
	#
	if [ ! -f "${SRCTOP}/${META_JSON_FILE}" ]; then
		PRNINFO "Not found ${META_JSON_FILE} file."
		return 1
	fi

	#
	# Print binary file information
	#
	PRNINFO "Seup local asset file:"
	sed -e 's#^#    #g' "${SRCTOP}/${META_JSON_FILE}" 2>/dev/null
	echo ""

	return 0
}

#
# Download asset files and Install it
#
check_and_download_asset_file()
{
	#
	# Check curl
	#
	if ! CURLCMD=$(command -v curl); then
		PRNINFO "Not found curl command"
		return 1
	fi

	#
	# Download TGZ and sha256 file
	#
	if ! _RESULT_CODE=$("${CURLCMD}" -s -S -L -w '%{http_code}' -o "${SRCTOP}/${ASSET_TGZ_FILENAME}" -X GET "${ASSET_TGZ_DOWNLOAD_URL}" --insecure); then
		PRNINFO "Failed to get download tgz file(${ASSET_TGZ_FILENAME})."
		rm -f "${SRCTOP}/${ASSET_TGZ_FILENAME}" 2>/dev/null
		return 1
	fi
	if [ -z "${_RESULT_CODE}" ] || [ "${_RESULT_CODE}" -ne 200 ]; then
		PRNINFO "Not found ${ASSET_TGZ_FILENAME}(http status code: (${_RESULT_CODE})."
		rm -f "${SRCTOP}/${ASSET_TGZ_FILENAME}" 2>/dev/null
		return 1
	fi
	if [ ! -f "${SRCTOP}/${ASSET_TGZ_FILENAME}" ]; then
		PRNINFO "Not found ${ASSET_TGZ_FILENAME} file."
		return 1
	fi
	if ! _RESULT_CODE=$("${CURLCMD}" -s -S -L -w '%{http_code}' -o "${SRCTOP}/${ASSET_SHA256_FILENAME}" -X GET "${ASSET_SHA256_DOWNLOAD_URL}" --insecure); then
		PRNINFO "Failed to get sha256 file(${ASSET_SHA256_FILENAME})."
		rm -f "${SRCTOP}/${ASSET_SHA256_FILENAME}" 2>/dev/null
		return 1
	fi
	if [ -z "${_RESULT_CODE}" ] || [ "${_RESULT_CODE}" -ne 200 ]; then
		PRNINFO "Not found ${ASSET_SHA256_FILENAME}(http status code: ${_RESULT_CODE})."
		rm -f "${SRCTOP}/${ASSET_SHA256_FILENAME}" 2>/dev/null
		return 1
	fi
	if [ ! -f "${SRCTOP}/${ASSET_SHA256_FILENAME}" ]; then
		PRNINFO "Not found ${ASSET_SHA256_FILENAME} file."
		return 1
	fi

	#
	# Check sha256
	#
	SHA256_VALUE=$(awk '{print $1}' "${SRCTOP}/${ASSET_SHA256_FILENAME}" 2>/dev/null | tr -d '\n')
	if ! DL_TGZ_SHA256_VALUE=$(sha256sum "${SRCTOP}/${ASSET_TGZ_FILENAME}" 2>/dev/null | awk '{print $1}' 2>/dev/null | tr -d '\n'); then
		PRNINFO "Failed to make sha256 value from download tgz file."
		return 1
	fi
	if [ -z "${SHA256_VALUE}" ] || [ -z "${DL_TGZ_SHA256_VALUE}" ] || [ "${SHA256_VALUE}" != "${DL_TGZ_SHA256_VALUE}" ]; then
		PRNINFO "The sha256 value of the downloaded tgz file is incorrect."
		return 1
	fi

	#
	# Exract file from tgz file
	#
	_CUR_DIR=$(pwd)
	cd "${SRCTOP}" || exit 1
	if ! tar xvfz "${SRCTOP}/${ASSET_TGZ_FILENAME}" >/dev/null 2>&1; then
		PRNINFO "Could not extract files from ${ASSET_TGZ_FILENAME} file."
		cd "${_CUR_DIR}" || exit 1
		return 1
	fi
	cd "${_CUR_DIR}" || exit 1

	#
	# metadata.json file
	#
	if [ ! -f "${SRCTOP}/${META_JSON_FILE}" ]; then
		PRNINFO "Not found ${META_JSON_FILE} file."
		return 1
	fi

	#
	# Print binary file information
	#
	PRNINFO "Download asset file:"
	sed -e 's#^#    #g' "${SRCTOP}/${META_JSON_FILE}" 2>/dev/null
	echo ""

	return 0
}

#==============================================================
# Check environments
#==============================================================
# [NOTE]
# If ANTPICKAX_SKIP_PREBUILD_INSTALL is set (true/1), it will
# return the same result as if the binary was found.
#
if [ -n "${ANTPICKAX_SKIP_PREBUILD_INSTALL}" ] && echo "${ANTPICKAX_SKIP_PREBUILD_INSTALL}" | grep -q -i -e 'true' -e '1'; then
	#
	# Skip all check
	#
	PRNSUCCESS "\"ANTPICKAX_SKIP_PREBUILD_INSTALL\" environment is set, so no binaries check and skip prebuild-install."
	exit 0
fi

#==============================================================
# Check local binary files
#==============================================================
PRNTITLE "Check local binary files"

# [NOTE]
# Check *.node in build/Release directory
#
if [ -d "${SRCTOP}/build/Release" ] && find "${SRCTOP}/build/Release" -maxdepth 1 -name \*.node -print -quit | grep -q .; then
	PRNSUCCESS "Found local binary files."
	exit 0
fi
PRNINFO "Not found local binary files."

#==============================================================
# Check binary tgz file in NPM package
#==============================================================
PRNTITLE "Check local asset file and Setup it"

if check_and_setup_local_asset_file; then
	PRNSUCCESS "Downloaded and Installed binaries from github asset."
	exit 0
fi
PRNINFO "Could not find local asset file or setup it."

#==============================================================
# Check asset file and Download it
#==============================================================
PRNTITLE "Check asset file and Download it"

if check_and_download_asset_file; then
	PRNSUCCESS "Downloaded and Installed binaries from github asset."
	exit 0
fi
PRNINFO "Could not download or install binaries from github asset."

#==============================================================
# Finished all check
#==============================================================
PRNINFO "Need to build all binaries locally, because neither local nor asset file installations worked."
echo ""

exit 1

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
