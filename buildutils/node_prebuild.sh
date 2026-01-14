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
# Variables for prebuild
#
PREBUILD_NAME="prebuild"
PREBUILD_PARAMTERS=$("${MAKE_VARS_BIN}" --prebuild-parameters)
PREBUILD_OUTPUT_DIR=$("${MAKE_VARS_BIN}" --output-dirname)
PREBUILD_OUTPUT_FILENAME=$("${MAKE_VARS_BIN}" --prebuild-filename)
RENAMED_FILENAME=$("${MAKE_VARS_BIN}" --tgz-filename)
SHA256_FILENAME=$("${MAKE_VARS_BIN}" --sha256-filename)
RENAMED_TAR_FILENAME=$(echo "${RENAMED_FILENAME}" | sed 's#\.tar\.gz$#\.tar#g')

#
# Variables for metadata.json
#
META_PKG_NAME=$("${MAKE_VARS_BIN}" --package-name)
META_PKG_VERSION=$("${MAKE_VARS_BIN}" --package-version)
META_FILENAME="${RENAMED_FILENAME}"
META_PLATFORM=$("${MAKE_VARS_BIN}" --platform-name)
META_DISTRO=$("${MAKE_VARS_BIN}" --distro-name)
META_DISTRO_VER=$("${MAKE_VARS_BIN}" --distro-version)
META_ARCH=$("${MAKE_VARS_BIN}" --architecture-name)
META_NODE_VER_MAJOR=$("${MAKE_VARS_BIN}" --node-major-version)
META_NODE_VER_FULL=$("${MAKE_VARS_BIN}" --node-version)
META_ABI_VER=$("${MAKE_VARS_BIN}" --node-abi-version)
META_NAPI_VER=$("${MAKE_VARS_BIN}" --napi-version)
META_LIBC_TYPE=$("${MAKE_VARS_BIN}" --libc-type)
META_BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if command -v git >/dev/null 2>&1; then
	META_GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
else
	META_GIT_HASH=""
fi

#==============================================================
# Utility functions and variables for messaging
#==============================================================
#
# Utilities for message
#
if [ -t 1 ] || { [ -n "${CI}" ] && [ "${CI}" = "true" ]; }; then
#	CBLD=$(printf '\033[1m')
	CREV=$(printf '\033[7m')
	CRED=$(printf '\033[31m')
	CYEL=$(printf '\033[33m')
	CGRN=$(printf '\033[32m')
	CDEF=$(printf '\033[0m')
else
#	CBLD=""
	CREV=""
	CRED=""
	CYEL=""
	CGRN=""
	CDEF=""
fi

PRNTITLE()
{
	echo ""
	echo "${CGRN}${CREV}[TITLE]${CDEF} ${CGRN}$*${CDEF}"
}

PRNMSG()
{
	echo ""
	echo "${CYEL}${CREV}[MSG]${CDEF} ${CYEL}$*${CDEF}"
}

PRNINFO()
{
	echo "${CREV}[INFO]${CDEF} $*"
}

PRNWARN()
{
	echo "${CYEL}${CREV}[WARNING]${CDEF} ${CYEL}$*${CDEF}"
}

PRNERR()
{
	echo "${CRED}${CREV}[ERROR]${CDEF} ${CRED}$*${CDEF}"
}

PRNSUCCESS()
{
	echo ""
	echo "${CGRN}${CREV}[SUCCEED]${CDEF} ${CGRN}$*${CDEF}"
	echo ""
}

#PRNFAILURE()
#{
#	echo "${CBLD}${CRED}${CREV}[FAILURE]${CDEF} ${CRED}$*${CDEF}"
#}

#==============================================================
# Create binary package with metadata.json and sigunature file
#==============================================================
PRNTITLE "Create binary package with metadata.json and sigunature files"

#
# Check prebuild tool
#
if [ -x "${SRCTOP}/node_modules/.bin/${PREBUILD_NAME}" ]; then
	PREBUILD_BIN="${SRCTOP}/node_modules/.bin/${PREBUILD_NAME}"
elif command -v "${PREBUILD_NAME}" >/dev/null 2>&1; then
	PREBUILD_BIN="$(command -v ${PREBUILD_NAME})"
else
	PRNERR "Not found ${PREBUILD_NAME} tool, please install it before run this script."
	exit 1
fi

#
# Check output directory
#
if [ ! -d "${SRCTOP}/${PREBUILD_OUTPUT_DIR}" ]; then
	if ! mkdir -p "${SRCTOP}/${PREBUILD_OUTPUT_DIR}" >/dev/null 2>&1; then
		PRNERR "Could not create ${PREBUILD_OUTPUT_DIR} directory."
		exit 1
	fi
fi

#--------------------------------------------------------------
# Create binary package
#--------------------------------------------------------------
PRNMSG "Run prebuild: \"GYP_DEFINES=openssl_fips= ${PREBUILD_BIN} ${PREBUILD_PARAMTERS}\""

if ({ /bin/sh -c "GYP_DEFINES=openssl_fips= ${PREBUILD_BIN} ${PREBUILD_PARAMTERS}" 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's|^|    |g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to run ${PREBUILD_NAME}."
	exit 1
fi

#
# Check output file
#
if [ ! -f "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${PREBUILD_OUTPUT_FILENAME}" ]; then
	PRNERR "Not found ${PREBUILD_OUTPUT_FILENAME} file in ${PREBUILD_OUTPUT_DIR} directory."
	exit 1
fi

PRNINFO "Succeed to run prebuild"

#--------------------------------------------------------------
# Make temporary directory and Extract tgz and Make metadata.json
#--------------------------------------------------------------
PRNMSG "Re-pack binary file with metadata.json"

#
# Create work directory
#
_TMP_DIR=$(mktemp -d)
_CUR_DIR=$(pwd)
cd "${_TMP_DIR}" || exit 1

#
# Extract tgz file
#
if ! tar xvfz "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${PREBUILD_OUTPUT_FILENAME}" >/dev/null 2>&1; then
	PRNERR "Failed to extract ${PREBUILD_OUTPUT_FILENAME} to ${_TMP_DIR}."
	exit 1
fi

#
# Create metadata.json
#
{
	echo '{'
	echo "  \"module\": \"${META_PKG_NAME}\","
	echo "  \"version\": \"${META_PKG_VERSION}\","
	echo "  \"filename\": \"${META_FILENAME}\","
	echo "  \"platform\": \"${META_PLATFORM}\","

	if [ -n "${META_DISTRO}" ]; then
		echo "  \"distro\": \"${META_DISTRO}\","

		if [ -n "${META_DISTRO_VER}" ]; then
			echo "  \"distro_version\": \"${META_DISTRO_VER}\","
		fi
	fi

	echo "  \"arch\": \"${META_ARCH}\","
	echo "  \"node_major\": \"${META_NODE_VER_MAJOR}\","
	echo "  \"node_full\": \"${META_NODE_VER_FULL}\","
	echo "  \"abi\": \"${META_ABI_VER}\","
	echo "  \"napi\": \"${META_NAPI_VER}\","
	echo "  \"libc\": \"${META_LIBC_TYPE}\","
	echo "  \"build_date\": \"${META_BUILD_DATE}\","

	if [ -n "${META_GIT_HASH}" ]; then
		echo "  \"git_commit\": \"${META_GIT_HASH}\","
	fi

	echo '  "builder": "AntPickax Node addon prebuild helper"'
	echo '}'
} > "${META_JSON_FILE}"

PRNINFO "Created ${META_JSON_FILE}:"
sed -e 's#^#    #g' "${META_JSON_FILE}"
echo ""

#
# Set file permission
#
_TMP_ALL_FILES=$(find . -type f 2>/dev/null)
_TMP_ALL_TARGETS=""
for _ONE_FILE in ${_TMP_ALL_FILES}; do
	if echo "${_ONE_FILE}" | grep -q '\.node$'; then
		# *.node file
		if ! chmod 0755 "${_ONE_FILE}" >/dev/null 2>&1; then
			PRNERR "Could not change permission 0755 to ${_ONE_FILE}."
			exit 1
		fi
	else
		# other file
		if ! chmod 0644 "${_ONE_FILE}" >/dev/null 2>&1; then
			PRNERR "Could not change permission 0644 to ${_ONE_FILE}."
			exit 1
		fi
	fi
	_TMP_ALL_TARGETS="${_TMP_ALL_TARGETS} ${_ONE_FILE}"
done

#
# Recompress with metadata.json
#
if [ -f "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${RENAMED_FILENAME}" ]; then
	PRNWARN "Found ${RENAMED_FILENAME} file in ${PREBUILD_OUTPUT_DIR} directory, so try to remove it."
	rm -f "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${RENAMED_FILENAME}" >/dev/null 2>&1
fi

if ! /bin/sh -c "tar --owner=0 --group=0 -C ${_TMP_DIR} -cvf - ${_TMP_ALL_TARGETS} | gzip - > ${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${RENAMED_FILENAME}" >/dev/null 2>&1; then
	PRNERR "Failed to compress(gip) ${RENAMED_TAR_FILENAME} file."
	exit 1
fi

#
# Remove original tgz file(created by prebuild)
#
rm -f "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${PREBUILD_OUTPUT_FILENAME}" >/dev/null 2>&1

#
# Cleanup
#
cd "${_CUR_DIR}" || exit 1
rm -rf "${_TMP_DIR}" >/dev/null 2>&1

PRNINFO "Succeed to re-pack binary file with metadata.json"

#--------------------------------------------------------------
# Create signature(SHA256) for binary package
#--------------------------------------------------------------
PRNMSG "Create signature(SHA256) for binary package"

_CUR_DIR=$(pwd)
cd "${SRCTOP}/${PREBUILD_OUTPUT_DIR}" || exit 1

if ! sha256sum "${RENAMED_FILENAME}" > "${SHA256_FILENAME}" 2>/dev/null; then
	PRNERR "Failed to create signature(SHA256) for binary package"
	exit 1
fi
cd "${_CUR_DIR}" || exit 1

PRNINFO "Succeed to create signature(SHA256) for binary package"

#--------------------------------------------------------------
# Run build:ts
#--------------------------------------------------------------
PRNMSG "Run build:ts"

# [NOTE]
# When run prebuild, the build directory is recreated, so the
# type information file(index.js) will no longer exist.
# Therefore, we need to run npm run build:ts to recreate the
# necessary files.
#
if ({ npm run build:ts 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's|^|    |g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to run build:ts."
	exit 1
fi

PRNINFO "Succeed to run build:ts"

#==============================================================
# Finished and Print messages
#==============================================================
PRNSUCCESS "Created binary package with metadata.json and sigunature files"

echo "    ${CGRN}Directory${CDEF}:      ${PREBUILD_OUTPUT_DIR}"
echo "    ${CGRN}Binary file${CDEF}:    ${RENAMED_FILENAME}"
if ({ tar tvfz "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${RENAMED_FILENAME}" 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's|^|                      |g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to unzip ${RENAMED_FILENAME}"
	exit 1
fi
echo "    ${CGRN}Signature file${CDEF}: ${SHA256_FILENAME}"
if ({ cat "${SRCTOP}/${PREBUILD_OUTPUT_DIR}/${SHA256_FILENAME}" 2>&1 || echo > "${PIPEFAILURE_FILE}"; } | sed -e 's|^|                      |g') && rm "${PIPEFAILURE_FILE}" >/dev/null 2>&1; then
	PRNERR "Failed to dump ${SHA256_FILENAME}"
	exit 1
fi
echo ""

exit 0

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
