#!/bin/sh
#
# CHMPX
#
# Copyright 2015 Yahoo! JAPAN corporation.
#
# CHMPX is inprocess data exchange by MQ with consistent hashing.
# CHMPX is made for the purpose of the construction of
# original messaging system and the offer of the client
# library.
# CHMPX transfers messages between the client and the server/
# slave. CHMPX based servers are dispersed by consistent
# hashing and are automatically layouted. As a result, it
# provides a high performance, a high scalability.
#
# For the full copyright and license information, please view
# the license file that was distributed with this source code.
#
# AUTHOR:   Takeshi Nakatani
# CREATE:   Mon Oct 31 2016
# REVISION:
#

##############################################################
# Check pid file and initialize it
#
# $1 :	pid file path
#
initialize_pid_file()
{
	if [ "X$1" = "X" ]; then
		echo -n "[ERROR] there is no parameter. / "
		return 1
	fi

	if [ -f $1 ]; then
		#
		# get pids from file
		#
		PIDS=`cat $1`

		#
		# HUP
		#
		kill -HUP ${PIDS} > /dev/null 2>&1
		sleep 1

		#
		# force kill if exists yet
		#
		for tgpid in ${PIDS}; do
			ps -p ${tgpid} > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				kill -9 ${tgpid} > /dev/null 2>&1
				sleep 1
			fi
		done

		#
		# recheck pid
		#
		RESULT=""
		ZOMBIE=""
		for tgpid in ${PIDS}; do
			PSRES=`ps -p ${tgpid} > /dev/null 2>&1`
			if [ $? -eq 0 ]; then
				PSRES=`echo ${PSRES} | grep ${tgpid} | grep -v "defunct"`
				if [ "X${PSRES}" != "X" ]; then
					RESULT="${RESULT} ${tgpid}"
				else
					ZOMBIE="${ZOMBIE} ${tgpid}"
				fi
			fi
		done

		if [ "X${RESULT}" != "X" ]; then
			echo -n "[ERROR] could not stop process(${RESULT}) / "
			return 1
		fi

		if [ "X${ZOMBIE}" != "X" ]; then
			echo -n "[WARNING] could not stop process(${ZOMBIE}) because it was zombie, but we can continue... / "
		fi

		#
		# remove pid file
		#
		rm -f $1
	fi

	return 0
}

##############################################################
# Current environment
#
PROGRAM_NAME=`basename $0`
RUNDIR=`pwd`
SELFSCRIPTDIR=`dirname $0`
if [ "X$SELFSCRIPTDIR" = "X" -o "X$SELFSCRIPTDIR" = "X." ]; then
	TMP_BASENAME=`basename $0`
	TMP_FIRSTWORD=`echo $0 | awk -F"/" '{print $1}'`

	if [ "X$TMP_BASENAME" = "X$TMP_FIRSTWORD" ]; then
		# search path
		SELFSCRIPTDIR=`which $0`
		SELFSCRIPTDIR=`dirname $SELFSCRIPTDIR`
	else
		SELFSCRIPTDIR=.
	fi
fi
SELFSCRIPTDIR=`cd -P ${SELFSCRIPTDIR}; pwd`
SRCTOP=`cd -P ${SELFSCRIPTDIR}/..; pwd`
SRCDIR=${SRCTOP}/src
TESTDIR=${SELFSCRIPTDIR}

if [ "X${NODE_PATH}" != "X" ]; then
	CHMPX_NODE_PATH=${NODE_PATH}:
fi
CHMPX_NODE_PATH=${CHMPX_NODE_PATH}${SRCDIR}/build/Release

CHMPX_SERVER_PID_FILE=/tmp/test_helper_chmpx_server.pid
NODE_SERVER_PID_FILE=/tmp/test_helper_node_server.pid
CHMPX_SLAVE_PID_FILE=/tmp/test_helper_chmpx_slave.pid
NODE_SLAVE_PID_FILE=/tmp/test_helper_node_slave.pid

##############################################################
# Parameter
#
if [ "X$1" = "X" ]; then
	echo "[ERROR] parameter is not specified."
	echo ""
	echo "Usage: ${PROGRAM_NAME} [ start_chmpx_server | start_node_server | start_chmpx_slave | start_node_slave | stop_chmpx_server | stop_node_server | stop_chmpx_slave | stop_node_slave | stop_all ]"
	exit 1

elif [ "X$1" = "X-h" -o "X$1" = "X-help" ]; then
	echo "Usage: ${PROGRAM_NAME} [ start_chmpx_server | start_node_server | start_chmpx_slave | start_node_slave | stop_chmpx_server | stop_node_server | stop_chmpx_slave | stop_node_slave | stop_all ]"
	echo ""
	exit 0

elif [ "X$1" = "Xstart_chmpx_server" -o "X$1" = "XSTART_CHMPX_SERVER" ]; then
	SCRIPT_MODE=start_chmpx_server

elif [ "X$1" = "Xstart_node_server" -o "X$1" = "XSTART_NODE_SERVER" ]; then
	SCRIPT_MODE=start_node_server

elif [ "X$1" = "Xstart_chmpx_slave" -o "X$1" = "XSTART_CHMPX_SLAVE" ]; then
	SCRIPT_MODE=start_chmpx_slave

elif [ "X$1" = "Xstart_node_slave" -o "X$1" = "XSTART_NODE_SLAVE" ]; then
	SCRIPT_MODE=start_node_slave

elif [ "X$1" = "Xstop_chmpx_server" -o "X$1" = "XSTOP_CHMPX_SERVER" ]; then
	SCRIPT_MODE=stop_chmpx_server

elif [ "X$1" = "Xstop_node_server" -o "X$1" = "XSTOP_NODE_SERVER" ]; then
	SCRIPT_MODE=stop_node_server

elif [ "X$1" = "Xstop_chmpx_slave" -o "X$1" = "XSTOP_CHMPX_SLAVE" ]; then
	SCRIPT_MODE=stop_chmpx_slave

elif [ "X$1" = "Xstop_node_slave" -o "X$1" = "XSTOP_NODE_SLAVE" ]; then
	SCRIPT_MODE=stop_node_slave

elif [ "X$1" = "Xstop_all" -o "X$1" = "XSTOP_ALL" ]; then
	SCRIPT_MODE=stop_all

else
	echo "[ERROR] unknown parameter($1) is specified."
	echo ""
	exit 1
fi

##############################################################
# Do work
#
cd ${TESTDIR}

if [ "X${SCRIPT_MODE}" = "Xstart_chmpx_server" ]; then
	echo -n "Run chmpx server processes : "

	#
	# Process check
	#
	initialize_pid_file ${CHMPX_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop old chmpx server process."
		exit 1
	fi

	#
	# Run chmpx server process
	#
	chmpx -conf ${TESTDIR}/chmpx_server.ini -d silent > /dev/null 2>&1 &
	CHMPX_SERVER_PID=$!

	#
	# Check process
	#
	sleep 1
	ps -p ${CHMPX_SERVER_PID} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not run chmpx server process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo ${CHMPX_SERVER_PID} >> ${CHMPX_SERVER_PID_FILE}

	echo "[SUCCEED] chmpx server pid = ${CHMPX_SERVER_PID}"

elif [ "X${SCRIPT_MODE}" = "Xstart_node_server" ]; then
	echo -n "Run node chmpx server processes : "

	#
	# Process check
	#
	initialize_pid_file ${NODE_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop old node chmpx server process."
		exit 1
	fi

	#
	# Run node chmpx server process
	#
	TESTDIR_PATH=${TESTDIR} NODE_PATH=${CHMPX_NODE_PATH} node ${TESTDIR}/run_process_test_server.js > /dev/null 2>&1 &
	NODE_CHMPX_SERVER_PID=$!

	#
	# Check process
	#
	sleep 1
	ps -p ${NODE_CHMPX_SERVER_PID} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not run node chmpx server process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "[SUCCEED] node chmpx server pid = ${NODE_CHMPX_SERVER_PID}"

	echo ${NODE_CHMPX_SERVER_PID} >> ${NODE_SERVER_PID_FILE}

elif [ "X${SCRIPT_MODE}" = "Xstart_chmpx_slave" ]; then
	echo -n "Run chmpx slave processes : "

	#
	# Process check
	#
	initialize_pid_file ${CHMPX_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop old chmpx slave process."
		exit 1
	fi

	#
	# Run chmpx slave process
	#
	chmpx -conf ${TESTDIR}/chmpx_slave.ini -d silent > /dev/null 2>&1 &
	CHMPX_SLAVE_PID=$!

	#
	# Check process
	#
	sleep 1
	ps -p ${CHMPX_SLAVE_PID} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not run chmpx slave process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo ${CHMPX_SLAVE_PID} >> ${CHMPX_SLAVE_PID_FILE}

	echo "[SUCCEED] chmpx slave pid = ${CHMPX_SLAVE_PID}"

elif [ "X${SCRIPT_MODE}" = "Xstart_node_slave" ]; then
	echo -n "Run node chmpx slave processes : "

	#
	# Process check
	#
	initialize_pid_file ${NODE_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop old node chmpx slave process."
		exit 1
	fi

	#
	# Run node chmpx slave process
	#
	TESTDIR_PATH=${TESTDIR} NODE_PATH=${CHMPX_NODE_PATH} node ${TESTDIR}/run_process_test_slave.js > /dev/null 2>&1 &
	NODE_CHMPX_SLAVE_PID=$!

	#
	# Check process
	#
	sleep 1
	ps -p ${NODE_CHMPX_SLAVE_PID} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not run node chmpx slave process."
		exit 1
	fi

	#
	# set pid to file
	#
	echo "[SUCCEED] node chmpx slave pid = ${NODE_CHMPX_SLAVE_PID}"

	echo ${NODE_CHMPX_SLAVE_PID} >> ${NODE_SLAVE_PID_FILE}

elif [ "X${SCRIPT_MODE}" = "Xstop_chmpx_server" ]; then
	echo -n "Stop chmpx server processes : "

	#
	# Stop process
	#
	initialize_pid_file ${CHMPX_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop chmpx server process."
		exit 1
	fi
	echo "[SUCCEED] stop chmpx server"

elif [ "X${SCRIPT_MODE}" = "Xstop_node_server" ]; then
	echo -n "Stop node chmpx server processes : "

	#
	# Stop process
	#
	initialize_pid_file ${NODE_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop node chmpx server process."
		exit 1
	fi
	echo "[SUCCEED] stop node chmpx server"

elif [ "X${SCRIPT_MODE}" = "Xstop_chmpx_slave" ]; then
	echo -n "Stop chmpx slave processes : "

	#
	# Stop process
	#
	initialize_pid_file ${CHMPX_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop chmpx slave process."
		exit 1
	fi
	echo "[SUCCEED] stop chmpx slave"

elif [ "X${SCRIPT_MODE}" = "Xstop_node_slave" ]; then
	echo -n "Stop node chmpx slave processes : "

	#
	# Stop process
	#
	initialize_pid_file ${NODE_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo "[ERROR] could not stop node chmpx slave process."
		exit 1
	fi
	echo "[SUCCEED] stop node chmpx slave"

elif [ "X${SCRIPT_MODE}" = "Xstop_all" ]; then
	echo -n "Stop all processes : "

	initialize_pid_file ${NODE_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo -n "[ERROR] could not stop node chmpx slave process. / "
	fi

	initialize_pid_file ${CHMPX_SLAVE_PID_FILE}
	if [ $? -ne 0 ]; then
		echo -n "[ERROR] could not stop chmpx slave process. / "
	fi

	initialize_pid_file ${NODE_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo -n "[ERROR] could not stop node chmpx server process. / "
	fi

	initialize_pid_file ${CHMPX_SERVER_PID_FILE}
	if [ $? -ne 0 ]; then
		echo -n "[ERROR] could not stop chmpx server process. / "
	fi
	echo "[FINISH] tried to stop all processes."
fi

exit 0

#
# VIM modelines
#
# vim:set ts=4 fenc=utf-8:
#
