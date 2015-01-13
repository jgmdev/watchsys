#!/bin/bash
########################################################################
# author: Jefferson González <jgmdev@gmail.com>                        #
# copyright: 2015 Jefferson González                                   #
#                                                                      #
# This file is part of WatchSys, which is under the GPLv3 License.     #
# See the LICENSE file or visit <http://www.gnu.org/licenses/>         #
########################################################################

clear

echo "Uninstalling WatchSys"

if [ -e '/etc/init.d/watchsys' ]; then
	echo; echo -n "Deleting init service..."
	UPDATERC_PATH=`whereis update-rc.d`
	if [ "$UPDATERC_PATH" != "update-rc.d:" ]; then
		service watchsys stop > /dev/null 2>&1
		update-rc.d watchsys remove > /dev/null 2>&1
	fi
	rm -f /etc/init.d/watchsys
	echo -n ".."
	echo " (done)"
fi

if [ -e '/usr/lib/systemd/system/watchsys.service' ]; then
	echo; echo -n "Deleting systemd service..."
	SYSTEMCTL_PATH=`whereis update-rc.d`
	if [ "$SYSTEMCTL_PATH" != "systemctl:" ]; then
		systemctl stop watchsys > /dev/null 2>&1
		systemctl disable watchsys > /dev/null 2>&1
	fi
	rm -f /usr/lib/systemd/system/watchsys.service
	echo -n ".."
	echo " (done)"
fi

echo -n "Deleting script files..."
if [ -e '/usr/lib/watchsys' ]; then
	rm -rf /usr/lib/watchsys
	echo -n "."
fi
if [ -e '/usr/bin/watchsys' ]; then
	rm -f /usr/bin/watchsys
	echo -n "."
fi
if [ -e '/usr/share/doc/watchsys' ]; then
	rm -rf /usr/share/doc/watchsys
	echo -n "."
fi
if [ -e '/var/cache/watchsys' ]; then
	rm -rf /var/cache/watchsys
	echo -n "."
fi
if [ -e '/etc/logrotate.d/watchsys' ]; then
	rm -rf /etc/logrotate.d/watchsys
	echo -n "."
fi
if [ -e '/var/log/watchsys.log' ]; then
	rm -rf /var/log/watchsys.*
	echo -n "."
fi
echo " (done)"

echo -n "Removing man page..."
if [ -e '/usr/share/man/man1/watchsys.1' ]; then
	rm -f /usr/share/man/man1/watchsys.1
	echo -n "."
fi
if [ -e '/usr/share/man/man1/watchsys.1.gz' ]; then
	rm -f /usr/share/man/man1/watchsys.1.gz
	echo -n "."
fi
echo " (done)"

if [ -e '/etc/cron.d/watchsys' ]; then
	echo -n "Deleting cron job..."
	rm -f /etc/cron.d/watchsys
	echo -n ".."
	echo " (done)"
fi

echo; echo "Uninstall Complete!"; echo
