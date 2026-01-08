#
# CHMPX
#
# Copyright 2020 Yahoo Japan corporation.
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
# AUTHOR:   Takeshi Nakatani
# CREATE:   Wed, Nov 18 2020
# REVISION: 1.0
#

#===============================================================
# Configuration for nodejs_addon_helper.sh
#===============================================================
# This file is loaded into the nodejs_addon_helper.sh script.
# The nodejs_addon_helper.sh script is a Github Actions helper script that
# builds and packages the target repository.
# This file is mainly created to define variables that differ depending
# on the Node.js Major Version.
# It also contains different information(such as packages to install)
# for each repository.
#
# In the initial state, you need to set the following variables:
#   INSTALLER_BIN     : Package management command
#   UPDATE_CMD        : Update sub command for package management command
#   UPDATE_CMD_ARG    : Update sub command arguments for package management
#                       command
#   INSTALL_CMD       : Install sub command for package management command
#   INSTALL_CMD_ARG   : Install sub command arguments for package management
#                       command
#   INSTALL_AUTO_ARG  : No interaption arguments for package management
#                       command
#   INSTALL_QUIET_ARG : Output suppression parameters during installation
#   INSTALL_PKG_LIST  : A list of packages to be installed for build and
#                       packaging
#   NODEJS_PKG_LIST   : A list of packages for nodejs to build
#
#   IS_OS_UBUNTU      : Set to 1 for Ubuntu, 0 otherwise
#   IS_OS_DEBIAN      : Set to 1 for Debian, 0 otherwise
#   IS_OS_FEDORA      : Set to 1 for Fedora, 0 otherwise
#   IS_OS_ROCKY       : Set to 1 for Rocky, 0 otherwise
#   IS_OS_ALPINE      : Set to 1 for Alpine, 0 otherwise
#
#   IS_NPM_PUBLISHER  : Set to 1 when publishing a NPM package.
#                       Set this value to only one of the target nodejs
#                       major versions and OS types.
#   IS_TEST_CJS       : Set to 1 for testing with CommonJS compiled from
#                       Typescript test codes(mocha. chai)
#   PUBLISH_DOMAIN    : Publish to NPM domain(default: registry.npmjs.org)
#
# Set these variables according to the CI_NODEJS_MAJOR_VERSION variable.
# The value of the CI_NODEJS_MAJOR_VERSION variable matches the name of
# the Container used in Github Actions.
# Check the ".github/workflow/***.yml" file for the value.
#

#---------------------------------------------------------------
# Default values
#---------------------------------------------------------------
INSTALLER_BIN=""
UPDATE_CMD=""
UPDATE_CMD_ARG=""
INSTALL_CMD=""
INSTALL_CMD_ARG=""
INSTALL_AUTO_ARG=""
INSTALL_QUIET_ARG=""
INSTALL_PKG_LIST=""
NODEJS_PKG_LIST=""

IS_OS_UBUNTU=0
IS_OS_DEBIAN=0
IS_OS_FEDORA=0
IS_OS_ROCKY=0
IS_OS_ALPINE=0

IS_NPM_PUBLISHER=0
IS_TEST_CJS=0

PUBLISH_DOMAIN="registry.npmjs.org"

#---------------------------------------------------------------
# Variables for each Node.js Major Version
#---------------------------------------------------------------
#
# NodeJS Type
#
if [ -z "${CI_NODEJS_MAJOR_VERSION}" ]; then
	#
	# Unknown NodeJS : Nothing to do
	#
	:

elif [ "${CI_NODEJS_MAJOR_VERSION}" = "20"  ]; then
	# [NOTE]
	# When running tests in NodeJS 20 with TypeScript, Mocha will throw the
	# error ERR_REQUIRE_CYCLE_MODULE.
	# Currently, there is no workaround, so you will need to convert the test
	# scripts to CommonJS beforehand and run them as CommonJS.
	# Note that TypeScript tests are run in other NodeJS versions, so there
	# is no problem.
	#
	IS_TEST_CJS=1

elif [ "${CI_NODEJS_MAJOR_VERSION}" = "22"  ]; then
	# Nothing to do
	:
elif [ "${CI_NODEJS_MAJOR_VERSION}" = "24"  ]; then
	# Nothing to do
	:
else
	#
	# Unknown OS : Nothing to do
	#
	:
fi

#
# OS Type
#
if [ -z "${CI_OSTYPE}" ]; then
	#
	# Unknown OS : Nothing to do
	#
	:

elif echo "${CI_OSTYPE}" | grep -q -i -e "ubuntu:24.04" -e "ubuntu:noble"; then
	INSTALLER_BIN="apt-get"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-qq"
	INSTALL_PKG_LIST="git gcc g++ make procps ca-certificates gnupg libyaml-dev chmpx-dev k2hash-dev libssl-dev"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_UBUNTU=1

elif echo "${CI_OSTYPE}" | grep -q -i -e "ubuntu:22.04" -e "ubuntu:jammy"; then
	INSTALLER_BIN="apt-get"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-qq"
	INSTALL_PKG_LIST="git gcc g++ make procps ca-certificates gnupg libyaml-dev chmpx-dev k2hash-dev libssl-dev"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_UBUNTU=1

elif echo "${CI_OSTYPE}" | grep -q -i -e "debian:13" -e "debian:trixie"; then
	INSTALLER_BIN="apt-get"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-qq"
	INSTALL_PKG_LIST="git gcc g++ make procps ca-certificates gnupg libyaml-dev chmpx-dev k2hash-dev libssl-dev"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_DEBIAN=1

elif echo "${CI_OSTYPE}" | grep -q -i -e "debian:12" -e "debian:bookworm"; then
	INSTALLER_BIN="apt-get"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-qq"
	INSTALL_PKG_LIST="git gcc g++ make procps ca-certificates gnupg libyaml-dev chmpx-dev k2hash-dev libssl-dev"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_DEBIAN=1

elif echo "${CI_OSTYPE}" | grep -q -i -e "debian:11" -e "debian:bullseye"; then
	INSTALLER_BIN="apt-get"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-qq"
	INSTALL_PKG_LIST="git gcc g++ make procps ca-certificates gnupg libyaml-dev chmpx-dev k2hash-dev libssl-dev"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_DEBIAN=1

elif echo "${CI_OSTYPE}" | grep -q -i "rockylinux:10"; then
	INSTALLER_BIN="dnf"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="git gcc gcc-c++ make procps xz libyaml-devel chmpx-devel k2hash-devel openssl-devel"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_ROCKY=1

	#
	# Enable CRB repository for libyaml
	#
	if "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" 'dnf-command(config-manager)'; then
		if ! "${INSTALLER_BIN}" config-manager --set-enabled crb; then
			echo "[ERROR] Failed to enable CRB repository. The script doesn't break here, but fails to install the package."
		fi
	else
		echo "[ERROR] Failed to install \"dnf-command(config-manager)\". The script doesn't break here, but fails to install the package."
	fi

elif echo "${CI_OSTYPE}" | grep -q -i "rockylinux:9"; then
	INSTALLER_BIN="dnf"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="git gcc gcc-c++ make procps xz libyaml-devel chmpx-devel k2hash-devel openssl-devel"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_ROCKY=1

	#
	# Enable CRB repository for libyaml
	#
	if "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" 'dnf-command(config-manager)'; then
		if ! "${INSTALLER_BIN}" config-manager --set-enabled crb; then
			echo "[ERROR] Failed to enable CRB repository. The script doesn't break here, but fails to install the package."
		fi
	else
		echo "[ERROR] Failed to install \"dnf-command(config-manager)\". The script doesn't break here, but fails to install the package."
	fi

elif echo "${CI_OSTYPE}" | grep -q -i "rockylinux:8"; then
	INSTALLER_BIN="dnf"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="git gcc gcc-c++ make procps xz libyaml-devel chmpx-devel k2hash-devel nss-devel"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_ROCKY=1

	#
	# Enable CRB repository for libyaml
	#
	if "${INSTALLER_BIN}" "${INSTALL_CMD}" "${INSTALL_AUTO_ARG}" 'dnf-command(config-manager)'; then
		if ! "${INSTALLER_BIN}" config-manager --set-enabled crb; then
			echo "[ERROR] Failed to enable CRB repository. The script doesn't break here, but fails to install the package."
		fi
	else
		echo "[ERROR] Failed to install \"dnf-command(config-manager)\". The script doesn't break here, but fails to install the package."
	fi

	#
	# Need to upgrade g++(std=gnu++20) for node-gyp
	#
	if /bin/sh -c "${SUDO_CMD} ${INSTALLER_BIN} ${INSTALL_CMD} ${INSTALL_AUTO_ARG} dnf-plugins-core"; then
		if /bin/sh -c "${SUDO_CMD} ${INSTALLER_BIN} config-manager --set-enabled powertools"; then
			#
			# Add gcc packages
			#
			if /bin/sh -c "${SUDO_CMD} ${INSTALLER_BIN} ${INSTALL_CMD} ${INSTALL_AUTO_ARG} gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ scl-utils"; then
				#
				# Set environments
				#
				if [ -f /opt/rh/gcc-toolset-12/enable ]; then
					. /opt/rh/gcc-toolset-12/enable
				else
					echo "[ERROR] Failed to setup enviroments for gcc. The script doesn't break here, but fails to node addon build."
				fi
			else
				echo "[ERROR] Failed to install \"gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ scl-utils\". The script doesn't break here, but fails to node addon build."
			fi
		else
			echo "[ERROR] Failed to enable PowerTools repository. The script doesn't break here, but fails to node addon build."
		fi
	else
		echo "[ERROR] Failed to install \"dnf-plugins-core\". The script doesn't break here, but fails to node addon build."
	fi

	#
	# Requires python3.8 or higher
	#
	if /bin/sh -c "${SUDO_CMD} ${INSTALLER_BIN} ${INSTALL_CMD} ${INSTALL_AUTO_ARG} python38"; then
		if /bin/sh -c "${SUDO_CMD} alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 60"; then
			#
			# Force set python3 -> python3.8
			#
			if ! /bin/sh -c "${SUDO_CMD} alternatives --set python3 /usr/bin/python3.8"; then
				echo "[ERROR] Failed to change to python3.8 as default. The script doesn't break here, but fails to prebuild."
			fi
		else
			echo "[ERROR] Failed to add python3.8 to alternatives. The script doesn't break here, but fails to prebuild."
		fi
	else
		echo "[ERROR] Failed to install \"python38\". The script doesn't break here, but fails to prebuild."
	fi

elif echo "${CI_OSTYPE}" | grep -q -i "fedora:42"; then
	INSTALLER_BIN="dnf"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="git gcc gcc-c++ make procps xz libyaml-devel chmpx-devel k2hash-devel openssl-devel"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_FEDORA=1

elif echo "${CI_OSTYPE}" | grep -q -i "fedora:41"; then
	INSTALLER_BIN="dnf"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG=""
	INSTALL_CMD="install"
	INSTALL_CMD_ARG=""
	INSTALL_AUTO_ARG="-y"
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="git gcc gcc-c++ make procps xz libyaml-devel chmpx-devel k2hash-devel openssl-devel"
	NODEJS_PKG_LIST="nodejs"

	IS_OS_FEDORA=1

elif echo "${CI_OSTYPE}" | grep -q -i "alpine:3.22"; then
	INSTALLER_BIN="apk"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG="--no-progress"
	INSTALL_CMD="add"
	INSTALL_CMD_ARG="--no-progress --no-cache"
	INSTALL_AUTO_ARG=""
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="bash sudo git build-base util-linux-misc musl-locales tar procps yaml-dev chmpx-dev k2hash-dev openssl-dev"
	NODEJS_PKG_LIST="nodejs npm python3 icu-data-full"

	IS_OS_ALPINE=1

	if [ "${CI_NODEJS_MAJOR_VERSION}" != "22" ]; then
		NOT_PROVIDED_NODEVER=1
	fi

	# [NOTE]
	# Currently, Alpine 3.22 only supports NodeJS 22, so testing with
	# CommonJS should not be necessary, but an ERR_REQUIRE_CYCLE_MODULE
	# error occurs.
	# Therefore, set IS_TEST_CJS=1 and perform CommonJS testing.
	#
	IS_TEST_CJS=1

elif echo "${CI_OSTYPE}" | grep -q -i "alpine:3.21"; then
	INSTALLER_BIN="apk"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG="--no-progress"
	INSTALL_CMD="add"
	INSTALL_CMD_ARG="--no-progress --no-cache"
	INSTALL_AUTO_ARG=""
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="bash sudo git build-base util-linux-misc musl-locales tar procps yaml-dev chmpx-dev k2hash-dev openssl-dev"
	NODEJS_PKG_LIST="nodejs npm python3 icu-data-full"

	IS_OS_ALPINE=1

	if [ "${CI_NODEJS_MAJOR_VERSION}" != "22" ]; then
		NOT_PROVIDED_NODEVER=1
	fi

	# [NOTE]
	# Currently, Alpine 3.21 only supports NodeJS 22, so testing with
	# CommonJS should not be necessary, but an ERR_REQUIRE_CYCLE_MODULE
	# error occurs.
	# Therefore, set IS_TEST_CJS=1 and perform CommonJS testing.
	#
	IS_TEST_CJS=1

elif echo "${CI_OSTYPE}" | grep -q -i "alpine:3.20"; then
	INSTALLER_BIN="apk"
	UPDATE_CMD="update"
	UPDATE_CMD_ARG="--no-progress"
	INSTALL_CMD="add"
	INSTALL_CMD_ARG="--no-progress --no-cache"
	INSTALL_AUTO_ARG=""
	INSTALL_QUIET_ARG="-q"
	INSTALL_PKG_LIST="bash sudo git build-base util-linux-misc musl-locales tar procps yaml-dev chmpx-dev k2hash-dev openssl-dev"
	NODEJS_PKG_LIST="nodejs npm python3 icu-data-full"

	IS_OS_ALPINE=1

	if [ "${CI_NODEJS_MAJOR_VERSION}" != "20" ]; then
		NOT_PROVIDED_NODEVER=1
	fi

	# Force set flag for CommonJS test
	IS_TEST_CJS=1
fi

#
# Check NPM package publisher
#
# [NOTE]
# For NodeJS, there will only be one CI process that publishes NPM
# packages per OS and NodeJS version.
# Note that if you are uploading binaries to Github.com Asset, the
# upload will be performed by all CI processes.
#
if echo "${CI_OSTYPE}" | grep -q -i -e "ubuntu:24.04" -e "ubuntu:noble" && [ "${CI_NODEJS_MAJOR_VERSION}" = "24" ]; then
	IS_NPM_PUBLISHER=1
else
	IS_NPM_PUBLISHER=0
fi

#---------------------------------------------------------------
# Enable/Disable processing
#---------------------------------------------------------------
# [NOTE]
# Specify the phase of processing to use.
# The phases that can be specified are the following values, and
# the default is set for NodeJS processing.
# Setting this value to 1 enables the corresponding processing,
# setting it to 0 disables it.
#
#	<variable name>		<default value>
#	RUN_PRE_INSTALL			0
#	RUN_INSTALL				1
#	RUN_POST_INSTALL		0
#	RUN_PRE_AUDIT			0
#	RUN_AUDIT				1
#	RUN_POST_AUDIT			0
#	RUN_CPPCHECK			1
#	RUN_SHELLCHECK			1
#	RUN_CHECK_OTHER			0
#	RUN_PRE_BUILD			0
#	RUN_BUILD				1
#	RUN_POST_BUILD			0
#	RUN_PRE_TEST			1
#	RUN_TEST				1
#	RUN_POST_TEST			0
#	RUN_PRE_PUBLISH			1
#	RUN_PUBLISH				1
#	RUN_POST_PUBLISH		1
#

#---------------------------------------------------------------
# Variables for each process
#---------------------------------------------------------------
# [NOTE]
# Specify the following variables that can be specified in some
# processes.
# Each value has a default value for NodeJS processing.
#
#	CPPCHECK_TARGET					"."
#	CPPCHECK_BASE_OPT				"--quiet --error-exitcode=1 --inline-suppr -j 8 --std=c++17 --xml"
#	CPPCHECK_ENABLE_VALUES			"warning style information missingInclude"
#	CPPCHECK_IGNORE_VALUES			"unmatchedSuppression missingIncludeSystem normalCheckLevelMaxBranches"
#	CPPCHECK_BUILD_DIR				"/tmp/cppcheck"
#
#	SHELLCHECK_TARGET_DIRS			"."
#	SHELLCHECK_BASE_OPT				"--shell=sh"
#	SHELLCHECK_EXCEPT_PATHS			"/node_modules/ /build/ /src/build/"
#	SHELLCHECK_IGN					"SC1117 SC1090 SC1091"
#	SHELLCHECK_INCLUDE_IGN			"SC2034 SC2148"
#

#---------------------------------------------------------------
# Override function for processing
#---------------------------------------------------------------
#
# [NOTE]
# It is allowed to override the contents of each processing.
# Each processing is implemented by a function that can be
# overridden. Those default functions are implemented for NodeJS
# processing.
# If you want to change the processing, you can implement and
# override the following functions in this file. Those function
# should return 0 or 1 as a return value.
# For messages such as errors, you can use PRNERR, PRNWARN, PRNMSG,
# and PRNINFO defined in nodejs_addon_helper.sh.
#
#	<function name>		<which processing>			<implemented or not>
#	run_pre_install		: before installing npm packages	no
#	run_install			: installing npm packages			yes
#	run_post_install	: after installing npm packages		no
#	run_pre_audit		: before audit checking				no
#	run_audit			: audit checking					yes
#	run_post_audit		: after audit checking				no
#	run_cppcheck		: run cppcheck						yes
#	run_shellcheck		: run shellcheck					yes
#	run_othercheck		: run other checking				no
#	run_pre_build		: before building					no
#	run_build			: building							yes
#	run_post_build		: after building					no
#	run_pre_test		: before testing					yes
#	run_test			: testing							yes
#	run_post_test		: after testing						no
#	run_pre_publish		: before publishing package			yes
#	run_publish			: publishing package				yes
#	run_post_publish	: after publishing package			yes
#

#
# Override Audit
#
# [NOTE]
# Currently(2025/12), packages related to prebuild are experiencing
# unrecoverable errors. However, since these are errors related to
# packaging, we are continuing to process them.
# Once the errors have been resolved, please remove this override.
#
run_audit()
{
	if ! /bin/sh -c "npm audit"; then
		echo ""
		PRNWARN "Failed to run \"npm audit\", but will not stop due to this error."
		echo "          You should investigate this error."
		echo "          It may be an error in a package you use."
		echo "          We won't stop here in case npm audit fix can't fix it."
		return 0
	fi
	PRNINFO "Finished to run \"npm audit\"."

	return 0
}

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
