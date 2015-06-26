#!/bin/bash
########################################################################
# author: Jefferson González <jgmdev@gmail.com>                        #
# copyright: 2015 Jefferson González                                   #
#                                                                      #
# This file is part of WatchSys, which is under the GPLv3 License.     #
# See the LICENSE file or visit <http://www.gnu.org/licenses/>         #
########################################################################

if [ -e "$DESTDIR/usr/bin/watchsys" ]; then
    echo "Please un-install the previous version first"
    exit 0
else
    mkdir -p "$DESTDIR/usr/bin/"
fi

clear

if [ ! -d "$DESTDIR/etc/watchsys" ]; then
    mkdir -p "$DESTDIR/etc/watchsys"
fi

echo; echo 'Installing WatchSys v0.1'; echo

if [ ! -e "$DESTDIR/etc/watchsys/watchsys.conf" ]; then
    echo -n 'Adding: /etc/watchsys/watchsys.conf...'
    cp config/watchsys.conf "$DESTDIR/etc/watchsys/watchsys.conf" > /dev/null 2>&1
    echo " (done)"
fi

if [ ! -e "$DESTDIR/etc/watchsys/proc.list" ]; then
    echo -n 'Adding: /etc/watchsys/proc.list...'
    cp config/proc.list "$DESTDIR/etc/watchsys/proc.list" > /dev/null 2>&1
    echo " (done)"
fi

if [ ! -e "$DESTDIR/etc/watchsys/server.list" ]; then
    echo -n 'Adding: /etc/watchsys/server.list...'
    cp config/server.list "$DESTDIR/etc/watchsys/server.list" > /dev/null 2>&1
    echo " (done)"
fi

if [ ! -e "$DESTDIR/etc/watchsys/dir.list" ]; then
    echo -n 'Adding: /etc/watchsys/dir.list...'
    cp config/dir.list "$DESTDIR/etc/watchsys/dir.list" > /dev/null 2>&1
    echo " (done)"
fi

echo -n 'Adding: /usr/share/doc/watchsys/LICENSE...'
mkdir -p "$DESTDIR/usr/share/doc/watchsys"
cp LICENSE "$DESTDIR/usr/share/doc/watchsys/LICENSE" > /dev/null 2>&1
echo " (done)"

echo -n 'Adding: /usr/bin/watchsys...'
cp src/watchsys.sh "$DESTDIR/usr/bin/watchsys" > /dev/null 2>&1
chmod 0755 /usr/bin/watchsys > /dev/null 2>&1
echo " (done)"

echo -n 'Adding: /usr/lib/watchsys/ files...'
mkdir -p "$DESTDIR/usr/lib/watchsys"
cp src/functions.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_cpu.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_mem.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_disk.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_proc.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_servers.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
cp src/watch_directories.sh "$DESTDIR/usr/lib/watchsys/" > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_cpu.sh > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_mem.sh > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_disk.sh > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_proc.sh > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_servers.sh > /dev/null 2>&1
chmod 0755 /usr/lib/watchsys/watch_directories.sh > /dev/null 2>&1
echo " (done)"

echo -n 'Adding man page...'
mkdir -p "$DESTDIR/usr/share/man/man1/"
cp man/watchsys.1 "$DESTDIR/usr/share/man/man1/watchsys.1" > /dev/null 2>&1
chmod 0644 "$DESTDIR/usr/share/man/man1/watchsys.1" > /dev/null 2>&1
echo " (done)"

if [ -d /etc/logrotate.d ]; then
    echo -n 'Adding logrotate configuration...'
    mkdir -p "$DESTDIR/etc/logrotate.d/"
    cp system/watchsys.logrotate "$DESTDIR/etc/logrotate.d/watchsys" > /dev/null 2>&1
    chmod 0644 "$DESTDIR/etc/logrotate.d/watchsys"
    echo " (done)"
fi

echo;

if [ -d /etc/cron.d ]; then
    echo -n 'Creating cron to run script every minute...'
    mkdir -p "$DESTDIR/etc/cron.d/"
    cp system/watchsys.cron "$DESTDIR/etc/cron.d/watchsys" > /dev/null 2>&1
    chmod 0644 "$DESTDIR/etc/cron.d/watchsys"
    echo " (done)"
fi

if [ -d /etc/init.d ]; then
    echo -n 'Setting up init script...'
    mkdir -p "$DESTDIR/etc/init.d/"
    cp system/watchsys.initd "$DESTDIR/etc/init.d/watchsys" > /dev/null 2>&1
    chmod 0755 "$DESTDIR/etc/init.d/watchsys" > /dev/null 2>&1
    echo " (done)"

    # Check if update-rc is installed and activate service
    UPDATERC_PATH=`whereis update-rc.d`
    if [ "$UPDATERC_PATH" != "update-rc.d:" ] && [ "$DESTDIR" = "" ]; then
        echo -n "Activating watchsys service..."
        update-rc.d watchsys defaults > /dev/null 2>&1
        service watchsys start > /dev/null 2>&1
        echo " (done)"
    else
        echo "watchsys service needs to be manually started... (warning)"
    fi
elif [ -d /usr/lib/systemd/system ]; then
    echo -n 'Setting up systemd service...'
    mkdir -p "$DESTDIR/usr/lib/systemd/system/"
    cp system/watchsys.service "$DESTDIR/usr/lib/systemd/system/" > /dev/null 2>&1
    chmod 0755 "$DESTDIR/usr/lib/systemd/system/watchsys.service" > /dev/null 2>&1
    echo " (done)"

    # Check if systemctl is installed and activate service
    SYSTEMCTL_PATH=`whereis systemctl`
    if [ "$SYSTEMCTL_PATH" != "systemctl:" ] && [ "$DESTDIR" = "" ]; then
        echo -n "Activating watchsys service..."
        systemctl enable watchsys > /dev/null 2>&1
        systemctl start watchsys > /dev/null 2>&1
        echo " (done)"
    else
        echo "watchsys service needs to be manually started... (warning)"
    fi
fi

echo; echo 'Installation has completed!'
echo 'Config files are located at /etc/watchsys/'
echo
echo 'Please send in your comments and/or suggestions to:'
echo 'https://github.com/jgmdev/watchsys/issues'
echo

exit 0
