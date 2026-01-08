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

#---------------------------------------------------------------
# About this script
#---------------------------------------------------------------
# This script outputs parameters for the prebuild command according
# to the environment.
# The script will output the result corresponding to the specified
# option to stdout. If a value does not exist, an empty string
# will be returned. If an option is not specified, an error will
# be output to stderr.
#
# This script is used as follows:
#	CPU_ARCH_NAME=$(make_node_variables.sh --architecture-name)
#	PREBUILD_PARAMTERS=$(make_node_variables.sh -rp)
#
#---------------------------------------------------------------

#---------------------------------------------------------------
# Common Variables
#---------------------------------------------------------------
PRGNAME=$(basename "$0")
SCRIPTDIR=$(dirname "$0")
SCRIPTDIR=$(cd "${SCRIPTDIR}" || exit 1; pwd)
SRCTOP=$(cd "${SCRIPTDIR}/.." || exit 1; pwd)

OS_RELEASE_FILE="/etc/os-release"
PACKAGE_JSON_FILE="package.json"
OUTPUT_BASE_DIR="prebuilds"

#---------------------------------------------------------------
# Package name and Package version, Github repository (for asset url)
#---------------------------------------------------------------
PKG_NAME=""
PKG_VERSION=""
GITHUB_DOMAIN_NAME=""
GITHUB_API_DOMAIN_NAME=""
GITHUB_OWNER_NAME=""
GITHUB_REPO_NAME=""
if [ ! -f "${SRCTOP}/${PACKAGE_JSON_FILE}" ]; then
	echo "Not found ${PACKAGE_JSON_FILE} file" 1>&2
	exit 1
else
	PKG_NAME=$(grep -i '"name"' "${SRCTOP}/${PACKAGE_JSON_FILE}" | sed -e 's|[,"]||g' | awk '{print $2}')
	PKG_VERSION=$(grep -i '"version"' "${SRCTOP}/${PACKAGE_JSON_FILE}" | sed -e 's|[,"]||g' | awk '{print $2}')

	_TMP_REPO_URL=$(tr -d '\n' < "${SRCTOP}/${PACKAGE_JSON_FILE}" 2>/dev/null | sed -e 's#^.*\"repository\"[[:space:]]*:##g' -e 's#}.*$##g' -e 's#.*\"url\"[[:space:]]*:[[:space:]]*##g' -e 's#"##g' -e 's#^[[:space:]]*##g' -e 's#[[:space:]]*$##g')
	GITHUB_DOMAIN_NAME=$(printf '%s' "${_TMP_REPO_URL}" | sed -e 's#git@##g' -e 's#http.*://##g' -e 's#:.*$##g' -e 's#/.*$##g')
	GITHUB_API_DOMAIN_NAME="api.${GITHUB_DOMAIN_NAME}"
	GITHUB_OWNER_NAME=$(printf '%s' "${_TMP_REPO_URL}" | awk -F'[/.:]' '{print $(NF-2)}')
	GITHUB_REPO_NAME=$(printf '%s' "${_TMP_REPO_URL}" | awk -F'[/.:]' '{print $(NF-1)}')
fi

#---------------------------------------------------------------
# Libc type
#---------------------------------------------------------------
LIBC_TYPE=""
if [ ! -f "${OS_RELEASE_FILE}" ]; then
	LIBC_TYPE=""
	PREBUILD_LIBC_PARAM=""
	FILE_LIBC_PARAM=""
elif grep -q -i '^ID=[[:space:]]*alpine[[:space:]]*$' "${OS_RELEASE_FILE}"; then
	LIBC_TYPE="musl"
	PREBUILD_LIBC_PARAM="--libc ${LIBC_TYPE}"
	FILE_LIBC_PARAM="-${LIBC_TYPE}"
else
	LIBC_TYPE="glibc"
	PREBUILD_LIBC_PARAM="--libc ${LIBC_TYPE}"
	FILE_LIBC_PARAM="-${LIBC_TYPE}"
fi

#---------------------------------------------------------------
# Platform name
#---------------------------------------------------------------
PLATFORM_NAME=""
if command -v uname >/dev/null 2>&1; then
	PLATFORM_NAME=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' 2>/dev/null)
fi
if [ -z "${PLATFORM_NAME}" ]; then
	PLATFORM_NAME="unknown"
	PREBUILD_PLATFORM_PARAM=""
	FILE_PLATFORM_PARAM="-${PLATFORM_NAME}"
else
	PREBUILD_PLATFORM_PARAM="--platform ${PLATFORM_NAME}"
	FILE_PLATFORM_PARAM="-${PLATFORM_NAME}"
fi

#---------------------------------------------------------------
# Distribution
#---------------------------------------------------------------
#
# Distribution name
#
DISTRO_NAME=""
if [ -f "${OS_RELEASE_FILE}" ]; then
	DISTRO_NAME=$(grep -i '^ID=[[:space:]]*.*$' "${OS_RELEASE_FILE}" 2>/dev/null | sed -e 's#^ID=[[:space:]]*##g' -e 's#"##g' -e 's#^[[:space:]]*##g' -e 's#[[:space:]]*$##g' | tr -d '\n' 2>/dev/null)
fi

#
# Distribution Version
#
DISTRO_VERSION=""
DISTRO_MAJOR_VERSION=""
if [ -n "${DISTRO_NAME}" ]; then
	DISTRO_VERSION=$(grep -i '^VERSION_ID=[[:space:]]*.*$' "${OS_RELEASE_FILE}" 2>/dev/null | sed -e 's#^VERSION_ID=[[:space:]]*##g' -e 's#"##g' -e 's#^[[:space:]]*##g' -e 's#[[:space:]]*$##g' | tr -d '\n' 2>/dev/null)

	# [NOTE]
	# For ALPINE, we must assign not only the major number but also the minor number.
	#
	if echo "${DISTRO_NAME}" | grep -q -i 'alpine'; then
		DISTRO_MAJOR_VERSION=$(printf '%s' "${DISTRO_VERSION}" 2>/dev/null | sed -e 's#^\([0-9]\+\)\.\?\([0-9]\+\)\?\.\?.*#\1.\2#g' -e 's#\.$##g' 2>/dev/null)
	else
		DISTRO_MAJOR_VERSION=$(printf '%s' "${DISTRO_VERSION}" 2>/dev/null | sed -e 's#[\.].*##g' | tr -d '\n' 2>/dev/null)
	fi
fi

#---------------------------------------------------------------
# CPU Architecture
#---------------------------------------------------------------
CPU_ARCH_NAME=""
if command -v uname >/dev/null 2>&1; then
	CPU_ARCH_NAME=$(uname -m 2>/dev/null)
fi
if [ -z "${CPU_ARCH_NAME}" ]; then
	CPU_ARCH_NAME=""
	PREBUILD_ARCH_PARAM=""
	FILE_ARCH_PARAM=""
elif echo "${CPU_ARCH_NAME}" | grep -q -i "^x86[_]*64$"; then
	CPU_ARCH_NAME="x86_64"
	PREBUILD_ARCH_PARAM="--arch ${CPU_ARCH_NAME}"
	FILE_ARCH_PARAM="-${CPU_ARCH_NAME}"
else
	CPU_ARCH_NAME=""
	PREBUILD_ARCH_PARAM=""
	FILE_ARCH_PARAM=""
fi

#---------------------------------------------------------------
# Node version and Node ABI version and N-API version
#---------------------------------------------------------------
NODE_VER_FULL=""
NODE_VER_MAJOR=""
NODE_ABI_VER=""
NAPI_VER=""
if command -v node >/dev/null 2>&1; then
	NODE_VER_FULL=$(node -v 2>/dev/null | sed 's/^v//' 2>/dev/null)
	NODE_VER_MAJOR=$(printf '%s' "${NODE_VER_FULL}" 2>/dev/null | cut -d. -f1 2>/dev/null)
	NODE_ABI_VER=$(node -e "console.log(require('node-abi').getAbi('${NODE_VER_FULL}', 'node'))" 2>/dev/null)
	NAPI_VER=$(node -p "process.versions.napi" 2>/dev/null)
fi
if [ -z "${NODE_VER_FULL}" ] || [ -z "${NODE_VER_MAJOR}" ] || [ -z "${NODE_ABI_VER}" ]; then
	NODE_VER_FULL=0
	NODE_VER_MAJOR=0.0.0
	NODE_ABI_VER=0
	PREBUILD_TARGET_PARAM=""
	FILE_TARGET_PARAM=""
	FILE_ABI_PARAM=""
else
	PREBUILD_TARGET_PARAM="--target ${NODE_VER_FULL}"
	FILE_TARGET_PARAM="-node${NODE_VER_MAJOR}"
	FILE_ABI_PARAM="-node-v${NODE_ABI_VER}"
fi
if [ -z "${NAPI_VER}" ]; then
	NAPI_VER=0
	FILE_NAPI_PARAM=""
else
	FILE_NAPI_PARAM="-napi${NAPI_VER}"
fi
if [ -z "${DISTRO_NAME}" ] || [ -z "${DISTRO_VERSION}" ] || [ -z "${DISTRO_MAJOR_VERSION}" ]; then
	FILE_DISTRO_PARAM=""
else
	FILE_DISTRO_PARAM="-${DISTRO_NAME}${DISTRO_MAJOR_VERSION}"
fi

#---------------------------------------------------------------
# Create a variables
#---------------------------------------------------------------
# Output directory:
#	prebuilds
#	prebuilds/<scope>	: when package name has scope
#
# Output filename(created by prebuild):
#	<pkgname(no scope)>-v<pkg version>-node-v<ABI version>-<platform name><libc type>-<arch name>.tar.gz
#	pkgname-v1.0.0-node-v137-linuxglibc-x86_64.tar.gz
#
# Final filename(rename from output filename)
#	<pkgname(no scope)>-v<pkg version>-node-v<ABI version>-node<node major version>-napi<N-API version>-<platform name>-<distro name><distro major version>-<arch name>-<libc type>.tar.gz
#	pkgname-v1.0.0-node-v137-node22-napi10-linux-ubuntu24-x86_64-glibc.tar.gz
#
# Prebuild command parameters:
#	--strip --napi --platform <platform name> --arch <arch name> --target <node full version> --libc <libc type>
#	--strip --napi --platform linux --arch x86_64 --target 24.11.1 --libc glibc
#
if echo "${PKG_NAME}" | grep -q '/'; then
	PKG_SCOPE_NAME=$(echo "${PKG_NAME}" | sed 's:/[^/]*$::')
	PKG_NOSCOPE_NAME=$(echo "${PKG_NAME}" | sed 's:.*/::')
	OUTPUT_SUBDIR="/${PKG_SCOPE_NAME}"
else
	PKG_SCOPE_NAME=""
	PKG_NOSCOPE_NAME="${PKG_NAME}"
	OUTPUT_SUBDIR=""
fi

SHAR256_FILE_SUFFIX=".sha256"
OUTDIR_PATH="${OUTPUT_BASE_DIR}${OUTPUT_SUBDIR}"
PREBUILD_OUTPUT_TGZ="${PKG_NOSCOPE_NAME}-v${PKG_VERSION}${FILE_ABI_PARAM}${FILE_PLATFORM_PARAM}${LIBC_TYPE}${FILE_ARCH_PARAM}.tar.gz"
RENAME_PKG_TGZ="${PKG_NOSCOPE_NAME}-v${PKG_VERSION}${FILE_ABI_PARAM}${FILE_TARGET_PARAM}${FILE_NAPI_PARAM}${FILE_PLATFORM_PARAM}${FILE_DISTRO_PARAM}${FILE_ARCH_PARAM}${FILE_LIBC_PARAM}.tar.gz"
RENAME_PKG_SHA256="${RENAME_PKG_TGZ}${SHAR256_FILE_SUFFIX}"
PREBUILD_PARAMTERS="--strip --napi ${PREBUILD_PLATFORM_PARAM} ${PREBUILD_ARCH_PARAM} ${PREBUILD_TARGET_PARAM} ${PREBUILD_LIBC_PARAM}"

#---------------------------------------------------------------
# Github asset urls
#---------------------------------------------------------------
# URL:
#	https://github.com/<owner>/<repo>/releases/download/v<version>/<tgz file name>
#	https://github.com/<owner>/<repo>/releases/download/v<version>/<sha256 file name>
#
GITHUB_ASSET_TGZ_URL="https://${GITHUB_DOMAIN_NAME}/${GITHUB_OWNER_NAME}/${GITHUB_REPO_NAME}/releases/download/v${PKG_VERSION}/${RENAME_PKG_TGZ}"
GITHUB_ASSET_SHA256_URL="https://${GITHUB_DOMAIN_NAME}/${GITHUB_OWNER_NAME}/${GITHUB_REPO_NAME}/releases/download/v${PKG_VERSION}/${RENAME_PKG_SHA256}"

#---------------------------------------------------------------
# Main process
#---------------------------------------------------------------
if [ $# -ne 1 ]; then
	echo "No parameters specified.(see --help option)" 1>&2
	exit 1

elif echo "$1" | grep -q -i -e "^--help$" -e "^-h$"; then
	echo ""
	echo "${PRGNAME}"
	echo "  This is a helper script that returns the current environment variables required when running the prebuild command to create a Nodejs addon package."
	echo ""
	echo "Usage:   ${PRGNAME} [options]"
	echo ""
	echo "Option:"
	echo "  --package-name(-pk)         : Get package name from package.json(ex. pkgname)"
	echo "  --package-version(-pv)      : Get package version from package.json(ex. 1.0.0)"
	echo "  --libc-type(-lt)            : Get LIBC type(ex. glibc or musl)"
	echo "  --platform-name(-pn)        : Get platform name(ex. linux, etc)"
	echo "  --distro-name(-dn)          : Get OS distribution name(ex. ubuntu, etc)"
	echo "  --distro-version(-dv)       : Get OS distribution version(ex. 24.04, etc)"
	echo "  --distro-major-version(-dm) : Get OS distribution major version(ex. 24, etc)"
	echo "  --architecture-name(-an)    : Get CPU architecture(ex. x86_64, etc)"
	echo "  --node-version(-nv)         : Get node full version(ex, 24.0.0)"
	echo "  --node-major-version(-nm)   : Get node mahor version(ex, 24)"
	echo "  --node-abi-version(-av)     : Get node ABI version(ex, 137)"
	echo "  --napi-version(-na)         : Get N-API library version(ex, 10)"
	echo "  --output-dirname(-od)       : Get directory name for prebuild output(ex, prebuilds or prebuilds/<scope>)"
	echo "  --prebuild-parameters(-pp)  : Get all prebuild command parameters(ex, --strip --napi --platform linux --arch x86_64 --target 24.11.1 --libc glibc)"
	echo "  --prebuild-filename(-pf)    : Get output filename created by prebuild under output directory(ex, <pkgname>-v1.0.0-node-v137-linuxglibc-x86_64.tar.gz)"
	echo "  --tgz-filename(-tf)         : Get the filename to rename the file created by prebuild(e.g. pkgname-v1.0.0-node-v137-node22-napi10-linux-x86_64-glibc.tar.gz)"
	echo "  --sha256-filename(-tf)      : Get the filename to sha256 file for renamed tgz file(e.g. pkgname-v1.0.0-node-v137-node22-napi10-linux-x86_64-glibc.tar.gz.sha256)"
	echo "  --tgz-download-url(-td)     : Get download URL for tgz asset file(e.g. https://github.com/<owner>/<repo>/releases/download/v<version>/<tgz file name>)"
	echo "  --sha256-download-url(-sd)  : Get download URL for sha256 asset file(e.g. https://github.com/<owner>/<repo>/releases/download/v<version>/<sha256 file name>)"
	echo "  --github-domain(-gd)        : Get github domain name(ex, github.com)"
	echo "  --github-api-domain(-ad)    : Get github api domain name(ex, api.github.com)"
	echo "  --package-owner(-po)        : Get github owner(organaization) name(ex, antpickax)"
	echo "  --package-repogitry(-pr)    : Get github repository name(ex, myrepository)"
	echo ""

elif echo "$1" | grep -q -i -e "^--package-name$" -e "^-pk$"; then
	printf '%s' "${PKG_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--package-version$" -e "^-pv$"; then
	printf '%s' "${PKG_VERSION}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--libc-type$" -e "^-lt$"; then
	printf '%s' "${LIBC_TYPE}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--platform-name$" -e "^-pn$"; then
	printf '%s' "${PLATFORM_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--distro-name$" -e "^--distribution-name$" -e "^-dn$"; then
	printf '%s' "${DISTRO_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--distro-version$" -e "^--distribution-version$" -e "^-dv$"; then
	printf '%s' "${DISTRO_VERSION}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--distro-major-version$" -e "^--distribution-major-version$" -e "^-dm$"; then
	printf '%s' "${DISTRO_MAJOR_VERSION}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--architecture-name$" -e "^-an$"; then
	printf '%s' "${CPU_ARCH_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--node-version$" -e "^-nv$"; then
	printf '%s' "${NODE_VER_FULL}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--node-major-version$" -e "^-nm$"; then
	printf '%s' "${NODE_VER_MAJOR}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--node-abi-version$" -e "^-av$"; then
	printf '%s' "${NODE_ABI_VER}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--napi-version$" -e "^-na$"; then
	printf '%s' "${NAPI_VER}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--output-dirname$" -e "^-od$"; then
	printf '%s' "${OUTDIR_PATH}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--prebuild-parameters$" -e "^-pp$"; then
	printf '%s' "${PREBUILD_PARAMTERS}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--prebuild-filename$" -e "^-pf$"; then
	printf '%s' "${PREBUILD_OUTPUT_TGZ}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--tgz-filename$" -e "^-rf$"; then
	printf '%s' "${RENAME_PKG_TGZ}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--sha256-filename$" -e "^-sf$"; then
	printf '%s' "${RENAME_PKG_SHA256}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--tgz-download-url$" -e "^-td$"; then
	printf '%s' "${GITHUB_ASSET_TGZ_URL}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--sha256-download-url$" -e "^-sd$"; then
	printf '%s' "${GITHUB_ASSET_SHA256_URL}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--github-domain$" -e "^-gd$"; then
	printf '%s' "${GITHUB_DOMAIN_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--github-api-domain$" -e "^-ad$"; then
	printf '%s' "${GITHUB_API_DOMAIN_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--package-owner$" -e "^-po$"; then
	printf '%s' "${GITHUB_OWNER_NAME}" 2>/dev/null

elif echo "$1" | grep -q -i -e "^--package-repogitry$" -e "^-pr$"; then
	printf '%s' "${GITHUB_REPO_NAME}" 2>/dev/null
fi

exit 0

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
