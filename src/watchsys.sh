#!/bin/bash
########################################################################
# author: Jefferson González <jgmdev@gmail.com>                        #
# copyright: 2015 Jefferson González                                   #
#                                                                      #
# This file is part of WatchSys, which is under the GPLv3 License.     #
# See the LICENSE file or visit <http://www.gnu.org/licenses/>         #
########################################################################

SOURCE_PATH="/usr/lib/watchsys"

source $SOURCE_PATH/functions.sh

load_conf

showhelp()
{
	head
	echo 'Usage: watchsys [OPTION]'
	echo
	echo 'OPTIONS:'
	echo '-h | --help: Show this help screen'
	echo '-d | --start: Initialize a daemon for monitoring'
	echo '-s | --stop: Stop the daemon'
	echo '-t | --status: Show status of daemon and pid if currently running'
}

# Executed as a cleanup function when the daemon is stopped
on_daemon_exit()
{
	if [ -e /var/run/watchsys.pid ]; then
		rm -f /var/run/watchsys.pid
	fi
	
	exit 0
}

# Return the current process id of the daemon or 0 if not running
daemon_pid()
{
	if [ -e /var/run/watchsys.pid ]; then
		echo $(cat /var/run/watchsys.pid)
		
		return
	fi
	
	echo "0"
}

# Check if daemon us running.
# Outputs 1 if running 0 if not.
daemon_running()
{
	if [ -e /var/run/watchsys.pid ]; then
		running_pid=$(ps -A | grep watchsys | awk '{print $1}')
		
		if [ "$running_pid" != "" ]; then
			current_pid=$(daemon_pid)
			
			for pid_num in $running_pid; do
				if [ "$current_pid" = "$pid_num" ]; then
					echo "1"
					return
				fi
			done
		fi
	fi

	echo "0"
}

start_daemon()
{
	su_required
	
	if [ $(daemon_running) = "1" ]; then
		echo "watchsys daemon is already running..."
		exit 0
	fi
	
	echo "starting watchsys daemon..."
	
	nohup $0 -l > /dev/null 2>&1 &
	
	log_msg "daemon started"
}

stop_daemon()
{
	su_required
	
	if [ $(daemon_running) = "0" ]; then
		echo "watchsys daemon is not running..."
		exit 0
	fi
	
	echo "stopping watchsys daemon..."
	
	kill $(daemon_pid)
	
	while [ -e /var/run/watchsys.pid ]; do
		continue
	done
	
	log_msg "daemon stopped"
}

daemon_loop()
{
	su_required
	
	if [ $(daemon_running) = "1" ]; then
		exit 0
	fi
	
	if [ ! -d /var/cache/watchsys ]; then
		mkdir -p /var/cache/watchsys
		mkdir -p /var/cache/watchsys/timers
	fi
	
	echo "$$" > /var/run/watchsys.pid
	
	trap 'on_daemon_exit' INT
	trap 'on_daemon_exit' QUIT
	trap 'on_daemon_exit' TERM
	trap 'on_daemon_exit' EXIT
	
	# Sleep to allow any processes to properly start
	#sleep 60
	
	while true; do
		if [ $ALLOW_THREADING -eq 1 ]; then
			. $SOURCE_PATH/watch_cpu.sh &
			. $SOURCE_PATH/watch_mem.sh &
			. $SOURCE_PATH/watch_disk.sh &
			. $SOURCE_PATH/watch_proc.sh &
			. $SOURCE_PATH/watch_servers.sh &
			. $SOURCE_PATH/watch_directories.sh &
		else
			monitor_cpu_usage
			monitor_memory_usage
			monitor_disk_usage
			monitor_services
			monitor_servers
			monitor_directories
		fi
		
		# Run monitors every 10 seconds
		sleep 10
	done
}

daemon_status()
{
	current_pid=$(daemon_pid)
	
	if [ $(daemon_running) = "1" ]; then
		echo "watchsys status: running with pid $current_pid"
	else
		echo "watchsys status: not running"
	fi
}

while [ $1 ]; do
	case $1 in
		'-h' | '--help' | '?' )
			showhelp
			exit
			;;
		'--start' | '-d' )
			start_daemon
			exit
			;;
		'--stop' | '-s' )
			stop_daemon
			exit
			;;
		'--status' | '-t' )
			daemon_status
			exit
			;;
		'--loop' | '-l' )
			# start daemon loop, used internally by --start | -s
			daemon_loop
			exit
			;;
		* )
			showhelp
			exit
			;;
	esac
	
	shift
done

showhelp

exit 0
