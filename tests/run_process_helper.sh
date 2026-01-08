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
TESTS_DIR="${SRCTOP}/tests"
CJS_TESTS_DIR="${SRCTOP}/tests_cjs"

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
		TMP_RUN_KILL=0
		for _one_pid in ${PIDS}; do
			# shellcheck disable=SC2009
			if ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${_one_pid}$" || exit 1 && exit 0 ); then
				kill -KILL "${_one_pid}" >/dev/null 2>&1
				TMP_RUN_KILL=1
			fi
		done
		if [ "${TMP_RUN_KILL}" -eq 1 ]; then
			sleep 2
		fi

		#
		# recheck pid
		#
		PROC_NOT_ZOMBIE=""
		PROC_ZOMBIE=""
		for _one_pid in ${PIDS}; do
			# shellcheck disable=SC2009
			if ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${_one_pid}$" || exit 1 && exit 0 ); then
				#
				# Found process id(not zombie)
				#
				PROC_NOT_ZOMBIE="${PROC_NOT_ZOMBIE} ${_one_pid}"
			else
				# shellcheck disable=SC2009
				if ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | grep -q "^${_one_pid}$" || exit 1 && exit 0 ); then
					#
					# Found process id(zombie)
					#
					PROC_ZOMBIE="${PROC_ZOMBIE} ${_one_pid}"
				else
					#
					# Not found process id
					#
					:
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
	echo "Usage: $1 [--help(-h)] [--commonjs(-cjs)] [ start_chmpx_server | start_node_server | start_chmpx_slave | start_node_slave | stop_chmpx_server | stop_node_server | stop_chmpx_slave | stop_node_slave | stop_all ]"
	echo ""
}

SCRIPT_MODE=""
IS_COMMON_JS=0

while [ $# -ne 0 ]; do
	if [ -z "$1" ]; then
		break

	elif echo "$1" | grep -q -i -e "^-h$" -e "^--help$"; then
		PrintUsage "${PRGNAME}"
		exit 0

	elif echo "$1" | grep -q -i -e "^-cjs$" -e "^--commonjs$"; then
		if [ "${IS_COMMON_JS}" -ne 0 ]; then
			echo "[ERROR] Already --commonjs(-cjs) option is specified."
			exit 1
		fi
		IS_COMMON_JS=1

	elif echo "$1" | grep -q -i "^start_chmpx_server$"; then
		SCRIPT_MODE="start_chmpx_server"

	elif echo "$1" | grep -q -i "^start_node_server$"; then
		SCRIPT_MODE="start_node_server"

	elif echo "$1" | grep -q -i "^start_chmpx_slave$"; then
		SCRIPT_MODE="start_chmpx_slave"

	elif echo "$1" | grep -q -i "^start_node_slave$"; then
		SCRIPT_MODE="start_node_slave"

	elif echo "$1" | grep -q -i "^stop_chmpx_server$"; then
		SCRIPT_MODE="stop_chmpx_server"

	elif echo "$1" | grep -q -i "^stop_node_server$"; then
		SCRIPT_MODE="stop_node_server"

	elif echo "$1" | grep -q -i "^stop_chmpx_slave$"; then
		SCRIPT_MODE="stop_chmpx_slave"

	elif echo "$1" | grep -q -i "^stop_node_slave$"; then
		SCRIPT_MODE="stop_node_slave"

	elif echo "$1" | grep -q -i "^stop_all$"; then
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

#----------------------------------------------------------
# Base directory and script type(CJS/TS)
#----------------------------------------------------------
if [ "${IS_COMMON_JS}" -eq 0 ]; then
	PROG_DIR="${TESTS_DIR}"
	JS_SUFFIX=".ts"
else
	PROG_DIR="${CJS_TESTS_DIR}"
	JS_SUFFIX=".js"
fi

#==========================================================
# Executing(current at TESTDIR)
#==========================================================
cd "${TESTS_DIR}" || exit 1

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
	chmpx -conf "${TESTS_DIR}"/chmpx_server.ini >/dev/null 2>&1 &
	CHMPX_SERVER_PID=$!
	sleep 1

	#
	# Check process
	#
	# shellcheck disable=SC2009
	if ! ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${CHMPX_SERVER_PID}$" || exit 1 && exit 0 ); then
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
	TESTS_PATH="${TESTS_DIR}" NODE_PATH="${CHMPX_NODE_PATH}" node "${PROG_DIR}/run_process_test_server${JS_SUFFIX}" >/dev/null 2>&1 &
	NODE_CHMPX_SERVER_PID=$!
	sleep 1

	#
	# Check process
	#
	# shellcheck disable=SC2009
	if ! ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${NODE_CHMPX_SERVER_PID}$" || exit 1 && exit 0 ); then
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
	chmpx -conf "${TESTS_DIR}"/chmpx_slave.ini >/dev/null 2>&1 &
	CHMPX_SLAVE_PID=$!
	sleep 1

	#
	# Check process
	#
	# shellcheck disable=SC2009
	if ! ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${CHMPX_SLAVE_PID}$" || exit 1 && exit 0 ); then
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
	TESTS_PATH="${TESTS_DIR}" NODE_PATH="${CHMPX_NODE_PATH}" node "${PROG_DIR}/run_process_test_slave${JS_SUFFIX}" >/dev/null 2>&1 &
	NODE_CHMPX_SLAVE_PID=$!
	sleep 1

	#
	# Check process
	#
	# shellcheck disable=SC2009
	if ! ( ps -o pid,stat ax 2>/dev/null | grep -v 'PID' | awk '$2~/^[^Z]/ { print $1 }' | grep -q "^${NODE_CHMPX_SLAVE_PID}$" || exit 1 && exit 0 ); then
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
