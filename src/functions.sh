#!/bin/bash
########################################################################
# author: Jefferson González <jgmdev@gmail.com>                        #
# copyright: 2015 Jefferson González                                   #
#                                                                      #
# This file is part of WatchSys, which is under the GPLv3 License.     #
# See the LICENSE file or visit <http://www.gnu.org/licenses/>         #
########################################################################

CONF_PATH="/etc/watchsys"

# Path of conf files
CONF_FILE="${CONF_PATH}/watchsys.conf"
SERVER_LIST="${CONF_PATH}/server.list"
PROC_LIST="${CONF_PATH}/proc.list"
DIR_LIST="${CONF_PATH}/dir.list"

# Labels for certain amount of seconds
THIRTHY_MIN=$((60 * 30))
ONE_HOUR=$((60 * 60))
SIX_HOURS=$((60 * 60 * 6))
TWELVE_HOURS=$((60 * 60 * 12))
ONE_DAY=$((60 * 60 * 24))
TWO_DAYS=$(($ONE_DAY * 2))

load_conf()
{
	if [ -f "$CONF_FILE" ] && [ ! "$CONF_FILE" == "" ]; then
		source $CONF_FILE
	fi
	
	detect_service_command
}

head()
{
	echo "WatchSys version 0.1"
	echo "Copyright (C) 2015, Jefferson González <jgmdev@gmail.com>"
	echo
}

# Check if super user is executing the 
# script and exit with message if not.
su_required()
{
	user_id=`id -u`
	
	if [ "$user_id" != "0" ]; then
		echo "You need super user priviliges for this."
		exit
	fi
}

log_msg()
{
	if [ ! -e /var/log/watchsys.log ]; then
		touch /var/log/watchsys.log
		chmod 0640 /var/log/watchsys.log
	fi
	
	echo "$(date +'[%Y-%m-%d %T]') $1" >> /var/log/watchsys.log
}

# Checks if a given amount of time for an identifier has
# already elapsed.
# param1 Identifier, eg: mem, cpu, dir, disk etc...
# param2 The amount of time in seconds
# returns 1 if the time in seconds already passed and 0 if not.
elapsed_time()
{
	TIME_FILE=/var/cache/watchsys/timers/$1.time
	
	if [ ! -e $TIME_FILE ]; then
		touch $TIME_FILE;
		return 1
	else
		PREVIOUS_TIME=`date +"%s" -r $TIME_FILE`
		CURRENT_TIME=`date +"%s"`
		
		ELAPSED_TIME=$(( $CURRENT_TIME - $PREVIOUS_TIME ))
		
		if [ $ELAPSED_TIME -ge $2 ]; then
			touch $TIME_FILE
			return 1
		fi
	fi
	
	return 0
}

# Detects how to start services and assings the value
# "systemctl", "service" or "initd" to $SERVICE_COMMAND
detect_service_command()
{
	SERVICE_COMMAND=""
	
	if [ -d /etc/init.d ]; then
		# Check if service is installed
		SERVICE_PATH=`whereis service`
		if [ "$SERVICE_PATH" != "service:" ]; then
			SERVICE_COMMAND="service"
		else
			SERVICE_COMMAND="initd"
		fi
	elif [ -d /usr/lib/systemd/system ]; then
		# Check if systemctl is installed
		SYSTEMCTL_PATH=`whereis systemctl`
		if [ "$SYSTEMCTL_PATH" != "systemctl:" ]; then
			SERVICE_COMMAND="systemctl"
		fi
	fi
	
	if [ "$SERVICE_COMMAND" = "" ]; then
		log_msg "error: command to start services not detected"
		echo "error: command to start services not detected" 1>&2
		exit 1
	fi
}

# Starts a service using apropiate command under current linux distro.
# param1 name of service
start_service()
{
	if [ "$SERVICE_COMMAND" = "systemctl" ]; then
		systemctl start $1
	elif [ "$SERVICE_COMMAND" = "service" ]; then
		service $1 start
	elif [ "$SERVICE_COMMAND" = "initd" ]; then
		/etc/init.d/$1 start
	else
		log_msg "error: command to start services not detected"
		exit 1
	fi
}

# Sends an email using the default system mail command or the value
# given on $CUSTOM_EMAIL_COMMAND
# param1 Subject
# param2 File with message to send.
send_email()
{
	if [ "$CUSTOM_EMAIL_COMMAND" != "" ]; then
		$CUSTOM_EMAIL_COMMAND "$EMAIL_TO" "$1" "$2" &
		return
	fi
    
	MESSAGE=`cat "$2" | mail -s "$1" $EMAIL_TO 2>&1`
    
    if [ "$(echo $MESSAGE | grep 'not sent')" != "" ]; then
        log_msg "error: could not send alert e-mail"
    fi
}

monitor_memory_usage()
{
	elapsed_time "mem_usage" $MEM_SCAN_INTERVAL
	
	if [ "$?" -eq 0 ]; then
		return
	fi
	
	MEM_USAGE_FILE=/var/cache/watchsys/mem_usage.txt
	
	TOTAL_MEM=$(free -mt | \
		grep "Mem:" | \
		awk '{print $2 " " $3}' | \
		awk '{ if($2 > 0) print $2 / $1 * 100; else print 0}'
	)
	
	TOTAL_SWP=$(free -mt | \
		grep "Swap:" | \
		awk '{print $2 " " $3}' | \
		awk '{ if($2 > 0) print $2 / $1 * 100; else print 0}'
	)
	
	echo "Output of free -mt" > $MEM_USAGE_FILE
	echo "" >> $MEM_USAGE_FILE
	free -m -t >> $MEM_USAGE_FILE
	echo "" >> $MEM_USAGE_FILE
	echo "Output of top -b -n 2" >> $MEM_USAGE_FILE
	echo "" >> $MEM_USAGE_FILE
	top -b -n 2 >> $MEM_USAGE_FILE

	TOTAL_MEM_INT=`echo $TOTAL_MEM | cut -d"." -f1`
	TOTAL_SWP_INT=`echo $TOTAL_SWP | cut -d"." -f1`
	
	if [ "$TOTAL_MEM_INT" -ge $CRITICAL_MEM ]; then
		log_msg "critical: memory usage reached ${TOTAL_MEM}%"
		
		elapsed_time "mem_email_critical" $MEM_EMAIL_CRIT_INTERVAL
		
		if [ "$?" -ge 1 ]; then
			send_email "Critical: Memory Usage ${TOTAL_MEM}%" \
				$MEM_USAGE_FILE
		fi
	elif [ "$TOTAL_MEM_INT" -ge $WARNING_MEM ]; then
		log_msg "warning: memory usage reached ${TOTAL_MEM}%"
		
		elapsed_time "mem_email_warning" $MEM_EMAIL_WARN_INTERVAL
		
		if [ "$?" -ge 1 ]; then
			send_email "Warning: Memory Usage ${TOTAL_MEM}%" \
				$MEM_USAGE_FILE
		fi
	fi

	if [ "$TOTAL_SWP_INT" -ge $CRITICAL_SWAP ]; then
		log_msg "critical: swap usage reached ${TOTAL_SWP}%"
		
		elapsed_time "swap_email_critical" $MEM_EMAIL_CRIT_INTERVAL
		
		if [ "$?" -ge 1 ]; then
			send_email "Critical: Swap Usage ${TOTAL_SWP}%" \
				$MEM_USAGE_FILE
		fi
	elif [ "$TOTAL_SWP_INT" -ge $WARNING_SWAP ]; then
		log_msg "warning: swap usage reached ${TOTAL}%"
		
		elapsed_time "swap_email_warning" $MEM_EMAIL_WARN_INTERVAL
		
		if [ "$?" -ge 1 ]; then
			send_email "Warning: Swap Usage ${TOTAL_SWP}%" \
				$MEM_USAGE_FILE
		fi
	fi
}

monitor_cpu_usage()
{
	elapsed_time "cpu_usage" $CPU_SCAN_INTERVAL
	
	if [ "$?" -eq 0 ]; then
		return
	fi
	
	CPU_USAGE_FILE=/var/cache/watchsys/cpu_usage.txt
	
	CPU_COUNT=`top -bn1 | grep Cpu | wc -l`
	
	echo "Output of top -b -n 2" > $CPU_USAGE_FILE
	echo "" >> $CPU_USAGE_FILE
	top -b -n 2 >> $CPU_USAGE_FILE

	USAGE_TOTAL=$(grep Cpu $CPU_USAGE_FILE | \
		grep -o -e "[0-9+]\.[0-9+]/" -e "[0-9+]\.[0-9+] us" | \
		grep -o -e "[0-9+]\.[0-9*]" | \
		tail -n +$(($CPU_COUNT + 1)) | \
		awk '{sum += $1}; END {print sum}'
	)

	TOTAL=$(echo "$USAGE_TOTAL $CPU_COUNT" | \
		awk '{print $1 / ($2 * 100) * 100}'
	)

	TOTAL_INT=`echo $TOTAL | cut -d"." -f1`

	if [ $TOTAL_INT -ge $CRITICAL_CPU ]; then
		log_msg "critical: cpu usage reached ${TOTAL}%"
		
		elapsed_time "cpu_email_critical" $CPU_EMAIL_CRIT_INTERVAL
		
		if [ "$?" -eq 1 ]; then
			send_email "Critical: Cpu Usage ${TOTAL}%" \
				$CPU_USAGE_FILE
		fi
	elif [ $TOTAL_INT -ge $WARNING_CPU ]; then
		log_msg "warning: cpu usage reached ${TOTAL}%"
		
		elapsed_time "cpu_email_warning" $CPU_EMAIL_WARN_INTERVAL
		
		if [ "$?" -eq 1 ]; then
			send_email "Warning: Cpu Usage ${TOTAL}%" \
				$CPU_USAGE_FILE
		fi
	fi
}

monitor_disk_usage()
{
	elapsed_time "disk_usage" $DISK_SCAN_INTERVAL
	
	if [ "$?" -eq 0 ]; then
		return
	fi
	
	DISK_USAGE_FILE=/var/cache/watchsys/disk_usage.txt
	
    TOTAL=0
    
    echo "Output of df -h" > $DISK_USAGE_FILE
    echo "" >> $DISK_USAGE_FILE

	df -h >> $DISK_USAGE_FILE
    
    CRITICAL_USAGE=0
    WARNING_USAGE=0

	while read line; do
		DEVICE=`echo $line | cut -d" " -f1`
        USAGE=`echo $line | cut -d" " -f5 | sed "s/%//"`
        
        if [ "$USAGE" -ge $CRITICAL_DISK ]; then
            log_msg "critical: disk usage reached ${USAGE}% on $DEVICE"
            CRITICAL_USAGE=1
        elif [ "$USAGE" -ge $WARNING_DISK ]; then
            log_msg "warning: disk usage reached ${USAGE}% on $DEVICE"
            WARNING_USAGE=1
        fi
	done < <(grep -v "tmp" $DISK_USAGE_FILE | grep "/dev/")

	if [ $CRITICAL_USAGE -eq 1 ]; then
		elapsed_time "disk_email_critical" $DISK_EMAIL_CRIT_INTERVAL
		
		if [ "$?" -eq 1 ]; then
			send_email "Critical: Disk Usage" $DISK_USAGE_FILE
		fi
	elif [ $WARNING_USAGE -eq 1 ]; then
		elapsed_time "disk_email_warning" $DISK_EMAIL_WARN_INTERVAL
		
		if [ "$?" -eq 1 ]; then
			send_email "Warning: Disk Usage" $DISK_USAGE_FILE
		fi
	fi
}

monitor_directories()
{
	echo "TODO" > /dev/null
}

monitor_servers()
{
	# Five minutes
	elapsed_time "servers_status" $SERVERS_SCAN_INTERVAL
	
	if [ "$?" -eq 0 ]; then
		return
	fi
	
	SERVERS_STATUS_FILE=/var/cache/watchsys/servers_status.txt
	
	echo "Offline servers:" > $SERVERS_STATUS_FILE
	echo "" >> $SERVERS_STATUS_FILE
	
	SERVER_OFFLINE=0
	
	while read line; do
		if [ "$line" = "" ]; then
			continue
		fi
		
		ip=`echo $line | cut -d":" -f1 | sed "s/ //"`
		port=`echo $line | cut -d":" -f2 | sed "s/ //"`
		
		if [ "$(echo $port | grep -i none)" = "" ]; then
			echo "QUIT" | netcat -w 5 -z $ip $port > /dev/null 2>&1
            
			if [ "$?" != "0" ]; then
				log_msg "warning: server $ip:$port seems offline"
				echo "$ip:$port" >> $SERVERS_STATUS_FILE
				SERVER_OFFLINE=1
			fi
		else
			ping -O -R -c 1 $ip > /dev/null 2>&1
            
			if [ "$?" != "0" ]; then
				log_msg "warning: server $ip seems offline"
				echo "$ip" >> $SERVERS_STATUS_FILE
				SERVER_OFFLINE=1
			fi
		fi
	done < <(grep -v "#" $SERVER_LIST)
    
	if [ $SERVER_OFFLINE -eq 1 ]; then
		elapsed_time "servers_email_status" $SERVERS_EMAIL_INTERVAL
		
		if [ "$?" -eq 0 ]; then
			return
		fi
		
		send_email "Warning: Servers seem offline" \
            $SERVERS_STATUS_FILE
	fi
}

monitor_services()
{
	# Five minutes
	elapsed_time "services_status" $PROC_SCAN_INTERVAL
	
	if [ "$?" -eq 0 ]; then
		return
	fi
	
	SERVICES_STATUS_FILE=/var/cache/watchsys/services_status.txt
	
	echo "Services status:" > $SERVICES_STATUS_FILE
	echo "" >> $SERVICES_STATUS_FILE
	
	SERVICES_DOWN=0
	
	while read line; do
		if [ "$line" = "" ]; then
			continue
		fi
		
		process=`echo $line | cut -d":" -f1 | sed "s/ //"`
		service=`echo $line | cut -d":" -f2 | sed "s/ //"`
		command=`echo $line | cut -d":" -f3 | sed "s/ //"`
		
		if [ "$(ps -A | grep $process)" != "" ]; then
			continue
		fi
		
		SERVICES_DOWN=1
		
		log_msg "warning: service $service not running"
		echo "service $service not running" >> $SERVICES_STATUS_FILE
		
		if [ "$(echo $command | grep -i default)" != "" ]; then
			start_service $service
		else
			$command &
		fi
	done < <(grep -v "#" $PROC_LIST)
    
	if [ $SERVICES_DOWN -eq 1 ]; then
		elapsed_time "services_email_status" $PROC_EMAIL_INTERVAL
		
		if [ "$?" -eq 0 ]; then
			return
		fi
		
		send_email "Warning: Services may have crashed" \
            $SERVICES_STATUS_FILE
	fi
}

# Default configuration values
EMAIL_TO="root"
CUSTOM_EMAIL_COMMAND=""
ALLOW_THREADING=1
CPU_SCAN_INTERVAL=30
MEM_SCAN_INTERVAL=30
DISK_SCAN_INTERVAL=$THIRTHY_MIN
PROC_SCAN_INTERVAL=$((60 * 3))
SERVERS_SCAN_INTERVAL=$((60 * 5))
CPU_EMAIL_WARN_INTERVAL=$ONE_DAY
CPU_EMAIL_CRIT_INTERVAL=$ONE_HOUR
MEM_EMAIL_WARN_INTERVAL=$ONE_DAY
MEM_EMAIL_CRIT_INTERVAL=$SIX_HOURS
DISK_EMAIL_WARN_INTERVAL=$ONE_DAY
DISK_EMAIL_CRIT_INTERVAL=$SIX_HOURS
PROC_EMAIL_INTERVAL=$((60 * 5))
SERVERS_EMAIL_INTERVAL=$SIX_HOURS
WARNING_CPU=75
WARNING_MEM=75
WARNING_SWAP=65
WARNING_DISK=75
CRITICAL_CPU=95
CRITICAL_MEM=90
CRITICAL_SWAP=80
CRITICAL_DISK=90
