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
# About this file
#---------------------------------------------------------------------
# This file is loaded into the nodejs_helper.sh script.
# The nodejs_helper.sh script is a Github Actions helper script that
# builds and packages the target repository.
# This file is mainly created to define variables that differ depending
# on the Node.js Major Version.
# It also contains different information(such as packages to install)
# for each repository.
#
# In the initial state, you need to set the following variables:
#   INSTALL_PKG_LIST  : A list of packages to be installed for build and
#                       packaging
#   INSTALLER_BIN     : Package management command
#   INSTALL_QUIET_ARG : Output suppression parameters during installation
#   PUBLISHER         : Set to true when publishing a package.
#                       Set this value to only one of the target nodejs
#                       major versions.
#
# Set these variables according to the NODE_MAJOR_VERSION variable.
# The value of the NODE_MAJOR_VERSION variable matches the name of the
# Container used in Github Actions.
# Check the ".github/workflow/***.yml" file for the value.
#

#---------------------------------------------------------------------
# Default values
#---------------------------------------------------------------------
INSTALL_PKG_LIST=
INSTALLER_BIN=
INSTALL_QUIET_ARG=
PUBLISHER=
DO_NOT_RUN_TEST=0

#---------------------------------------------------------------------
# Variables for each Node.js Major Version
#---------------------------------------------------------------------
if [ "X${NODE_MAJOR_VERSION}" = "X8" ]; then
	INSTALL_PKG_LIST="git gcc g++ make chmpx-dev"
	INSTALLER_BIN="apt-get"
	INSTALL_QUIET_ARG="-qq"
	PUBLISHER="false"

	# [NOTE]
	# Prior to Node.js version 10.x, tests cannot be run because await is not available.
	# It is an unsupported version, so just run the build to complete it.
	#
	DO_NOT_RUN_TEST=1

elif [ "X${NODE_MAJOR_VERSION}" = "X10" ]; then
	INSTALL_PKG_LIST="git gcc g++ make chmpx-dev"
	INSTALLER_BIN="apt-get"
	INSTALL_QUIET_ARG="-qq"
	PUBLISHER="false"

elif [ "X${NODE_MAJOR_VERSION}" = "X12" ]; then
	INSTALL_PKG_LIST="git gcc g++ make chmpx-dev"
	INSTALLER_BIN="apt-get"
	INSTALL_QUIET_ARG="-qq"
	PUBLISHER="false"

elif [ "X${NODE_MAJOR_VERSION}" = "X14" ]; then
	INSTALL_PKG_LIST="git gcc g++ make chmpx-dev"
	INSTALLER_BIN="apt-get"
	INSTALL_QUIET_ARG="-qq"
	PUBLISHER="true"

fi

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: noexpandtab sw=4 ts=4 fdm=marker
# vim<600: noexpandtab sw=4 ts=4
#
