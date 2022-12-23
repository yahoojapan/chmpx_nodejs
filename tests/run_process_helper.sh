#!/bin/sh
#
# CHMPX
#
# Copyright 2015 Yahoo Japan Corporation.
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
# CREATE:   Mon Oct 31 2016
# REVISION:
#

#==========================================================
# Common Variables
#==========================================================
PRGNAME=$(basename "$0")
SCRIPTDIR=$(dirname "$0")
SCRIPTDIR=$(cd "${SCRIPTDIR}" || exit 1; pwd)
SRCTOP=$(cd "${SCRIPTDIR}/.." || exit 1; pwd)
SRCDIR=$(cd "${SRCTOP}/src" || exit 1; pwd)
TESTSDIR=$(cd "${SRCTOP}/tests" || exit 1; pwd)

#
# pid files
#
CHMPX_SERVER_PID_FILE="/tmp/test_helper_chmpx_server.pid"
NODE_SERVER_PID_FILE="/tmp/test_helper_node_server.pid"
CHMPX_SLAVE_PID_FILE="/tmp/test_helper_chmpx_slave.pid"
NODE_SLAVE_PID_FILE="/tmp/test_helper_node_slave.pid"

#==========================================================
# Utilities
#==========================================================
#
# Check pid file and initialize it
#
# $1 :	pid file path
#
initialize_pid_file()
{
	if [ -z "$1" ]; then
		printf '[ERROR] there is no parameter. / '
		return 1
	fi

	if [ -f "$1" ]; then
		#
		# get pids from file
		#
		PIDS="$(tr '\n' ' ' < "$1")"

		#
		# HUP
		#
		/bin/sh -c "kill -HUP ${PIDS}" >/dev/null 2>&1
		sleep 1

		#
		# force kill if exists yet
		#
		for _one_pid in ${PIDS}; do
			if ps -p "${_one_pid}" >/dev/null 2>&1; then
				kill -9 "${_one_pid}" >/dev/null 2>&1
				sleep 1
			fi
		done

		#
		# recheck pid
		#
		PROC_NOT_ZOMBIE=""
		PROC_ZOMBIE=""
		for _one_pid in ${PIDS}; do
			# shellcheck disable=SC2009
			if PSRESULT=$(ps -p "${_one_pid}" 2>&1 | grep -v 'PID'); then
				if echo "${PSRESULT}" | grep "${_one_pid}" | grep -q 'defunct'; then
					PROC_ZOMBIE="${PROC_ZOMBIE} ${_one_pid}"
				else
					PROC_NOT_ZOMBIE="${PROC_NOT_ZOMBIE} ${_one_pid}"
				fi
			fi
		done

		if [ -n "${PROC_NOT_ZOMBIE}" ]; then
			printf '[ERROR] could not stop process(%s) / ' "${PROC_NOT_ZOMBIE}"
			return 1
		fi

		if [ -n "${PROC_ZOMBIE}" ]; then
			printf '[WARNING] could not stop process(%s) because it was zombie, but we can continue... / ' "${PROC_ZOMBIE}"
		fi

		#
		# remove pid file
		#
		rm -f "$1"
	fi
	return 0
}

#==========================================================
# Parse arguments
#==========================================================
PrintUsage()
{
	echo ""
	echo "Usage: $1 [--help(-h)] [ start_chmpx_server | start_node_server | start_chmpx_slave | start_node_slave | stop_chmpx_server | stop_node_server | stop_chmpx_slave | stop_node_slave | stop_all ]"
	echo ""
}

SCRIPT_MODE=""

while [ $# -ne 0 ]; do
	if [ -z "$1" ]; then
		break

	elif [ "$1" = "-h" ] || [ "$1" = "-H" ] || [ "$1" = "--help" ] || [ "$1" = "--HELP" ]; then
		PrintUsage "${PRGNAME}"
		exit 0

	elif [ "$1" = "start_chmpx_server" ] || [ "$1" = "START_CHMPX_SERVER" ]; then
		SCRIPT_MODE="start_chmpx_server"

	elif [ "$1" = "start_node_server" ] || [ "$1" = "START_NODE_SERVER" ]; then
		SCRIPT_MODE="start_node_server"

	elif [ "$1" = "start_chmpx_slave" ] || [ "$1" = "START_CHMPX_SLAVE" ]; then
		SCRIPT_MODE="start_chmpx_slave"

	elif [ "$1" = "start_node_slave" ] || [ "$1" = "START_NODE_SLAVE" ]; then
		SCRIPT_MODE="start_node_slave"

	elif [ "$1" = "stop_chmpx_server" ] || [ "$1" = "STOP_CHMPX_SERVER" ]; then
		SCRIPT_MODE="stop_chmpx_server"

	elif [ "$1" = "stop_node_server" ] || [ "$1" = "STOP_NODE_SERVER" ]; then
		SCRIPT_MODE="stop_node_server"

	elif [ "$1" = "stop_chmpx_slave" ] || [ "$1" = "STOP_CHMPX_SLAVE" ]; then
		SCRIPT_MODE="stop_chmpx_slave"

	elif [ "$1" = "stop_node_slave" ] || [ "$1" = "STOP_NODE_SLAVE" ]; then
		SCRIPT_MODE="stop_node_slave"

	elif [ "$1" = "stop_all" ] || [ "$1" = "STOP_ALL" ]; then
		SCRIPT_MODE="stop_all"

	else
		echo "[ERROR] unknown parameter($1) is specified."
		exit 1
	fi
	shift
done

if [ -z "${SCRIPT_MODE}" ]; then
	echo "[ERROR] No parameter is specified."
	exit 1
fi

#----------------------------------------------------------
# node path(relative path from SRCTOP) for chmpx
#----------------------------------------------------------
if [ -n "${NODE_PATH}" ]; then
	CHMPX_NODE_PATH="${NODE_PATH}:"
fi
CHMPX_NODE_PATH="${CHMPX_NODE_PATH}${SRCDIR}/build/Release"

#==========================================================
# Executing(current at TESTDIR)
#==========================================================
cd "${TESTSDIR}" || exit 1

#----------------------------------------------------------
# Do work
#----------------------------------------------------------
if [ "${SCRIPT_MODE}" = "start_chmpx_server" ]; then
	printf "Run chmpx server processes : "

	#
	# Process check
	#
	if ! initialize_pid_file "${CHMPX_SERVER_PID_FILE}"; then
		echo "[ERROR] could not stop old chmpx server process."
		exit 1
	fi

	#
	# Run chmpx server process
	#
	chmpx -conf "${TESTSDIR}"/chmpx_server.ini -d silent >/dev/null 2>&1 &
	CHMPX_SERVER_PID=$!

	#
	# Check process
	#
	sleep 1
	if ! ps -p "${CHMPX_SERVER_PID}" >/dev/null 2>&1; then
		echo "[ERROR] could not run chmpx server process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "${CHMPX_SERVER_PID}" >> "${CHMPX_SERVER_PID_FILE}"

	echo "[SUCCEED] chmpx server pid = ${CHMPX_SERVER_PID}"

elif [ "${SCRIPT_MODE}" = "start_node_server" ]; then
	printf "Run node chmpx server processes : "

	#
	# Process check
	#
	if ! initialize_pid_file "${NODE_SERVER_PID_FILE}"; then
		echo "[ERROR] could not stop old node chmpx server process."
		exit 1
	fi

	#
	# Run node chmpx server process
	#
	TESTDIR_PATH="${TESTSDIR}" NODE_PATH="${CHMPX_NODE_PATH}" node "${TESTSDIR}"/run_process_test_server.js >/dev/null 2>&1 &
	NODE_CHMPX_SERVER_PID=$!

	#
	# Check process
	#
	sleep 1
	if ! ps -p "${NODE_CHMPX_SERVER_PID}" >/dev/null 2>&1; then
		echo "[ERROR] could not run node chmpx server process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "${NODE_CHMPX_SERVER_PID}" >> "${NODE_SERVER_PID_FILE}"

	echo "[SUCCEED] node chmpx server pid = ${NODE_CHMPX_SERVER_PID}"

elif [ "${SCRIPT_MODE}" = "start_chmpx_slave" ]; then
	printf "Run chmpx slave processes : "

	#
	# Process check
	#
	if ! initialize_pid_file "${CHMPX_SLAVE_PID_FILE}"; then
		echo "[ERROR] could not stop old chmpx slave process."
		exit 1
	fi

	#
	# Run chmpx slave process
	#
	chmpx -conf "${TESTSDIR}"/chmpx_slave.ini -d silent >/dev/null 2>&1 &
	CHMPX_SLAVE_PID=$!

	#
	# Check process
	#
	sleep 1
	if ! ps -p "${CHMPX_SLAVE_PID}" >/dev/null 2>&1; then
		echo "[ERROR] could not run chmpx slave process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "${CHMPX_SLAVE_PID}" >> "${CHMPX_SLAVE_PID_FILE}"

	echo "[SUCCEED] chmpx slave pid = ${CHMPX_SLAVE_PID}"

elif [ "${SCRIPT_MODE}" = "start_node_slave" ]; then
	printf "Run node chmpx slave processes : "

	#
	# Process check
	#
	if ! initialize_pid_file "${NODE_SLAVE_PID_FILE}"; then
		echo "[ERROR] could not stop old node chmpx slave process."
		exit 1
	fi

	#
	# Run node chmpx slave process
	#
	TESTDIR_PATH="${TESTSDIR}" NODE_PATH="${CHMPX_NODE_PATH}" node "${TESTSDIR}"/run_process_test_slave.js >/dev/null 2>&1 &
	NODE_CHMPX_SLAVE_PID=$!

	#
	# Check process
	#
	sleep 1
	if ! ps -p "${NODE_CHMPX_SLAVE_PID}" >/dev/null 2>&1; then
		echo "[ERROR] could not run node chmpx slave process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "${NODE_CHMPX_SLAVE_PID}" >> "${NODE_SLAVE_PID_FILE}"

	echo "[SUCCEED] node chmpx slave pid = ${NODE_CHMPX_SLAVE_PID}"

elif [ "${SCRIPT_MODE}" = "stop_chmpx_server" ]; then
	printf "Stop chmpx server processes : "

	#
	# Stop process
	#
	if ! initialize_pid_file "${CHMPX_SERVER_PID_FILE}"; then
		echo "[ERROR] could not stop chmpx server process."
		exit 1
	fi
	echo "[SUCCEED] stop chmpx server"

elif [ "${SCRIPT_MODE}" = "stop_node_server" ]; then
	printf "Stop node chmpx server processes : "

	#
	# Stop process
	#
	if ! initialize_pid_file "${NODE_SERVER_PID_FILE}"; then
		echo "[ERROR] could not stop node chmpx server process."
		exit 1
	fi
	echo "[SUCCEED] stop node chmpx server"

elif [ "${SCRIPT_MODE}" = "stop_chmpx_slave" ]; then
	printf "Stop chmpx slave processes : "

	#
	# Stop process
	#
	if ! initialize_pid_file "${CHMPX_SLAVE_PID_FILE}"; then
		echo "[ERROR] could not stop chmpx slave process."
		exit 1
	fi
	echo "[SUCCEED] stop chmpx slave"

elif [ "${SCRIPT_MODE}" = "stop_node_slave" ]; then
	printf "Stop node chmpx slave processes : "

	#
	# Stop process
	#
	if ! initialize_pid_file "${NODE_SLAVE_PID_FILE}"; then
		echo "[ERROR] could not stop node chmpx slave process."
		exit 1
	fi
	echo "[SUCCEED] stop node chmpx slave"

elif [ "${SCRIPT_MODE}" = "stop_all" ]; then
	printf "Stop all processes : "

	_EXEC_ERROR=0
	if ! initialize_pid_file "${NODE_SLAVE_PID_FILE}"; then
		printf "[ERROR] could not stop node chmpx slave process. / "
		_EXEC_ERROR=1
	fi

	if ! initialize_pid_file "${CHMPX_SLAVE_PID_FILE}"; then
		printf "[ERROR] could not stop chmpx slave process. / "
		_EXEC_ERROR=1
	fi

	if ! initialize_pid_file "${NODE_SERVER_PID_FILE}"; then
		printf "[ERROR] could not stop node chmpx server process. / "
		_EXEC_ERROR=1
	fi

	if ! initialize_pid_file "${CHMPX_SERVER_PID_FILE}"; then
		printf "[ERROR] could not stop chmpx server process. / "
		_EXEC_ERROR=1
	fi

	if [ "${_EXEC_ERROR}" -ne 0 ]; then
		echo "[ERROR] Could not stop some processes."
		exit 1
	fi

	echo "[FINISH] tried to stop all processes."
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
