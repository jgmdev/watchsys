# WatchSys

Bash shell script for basic system monitoring and prevention.

## About

WatchSys is a set of bash shell scripts that run from a central daemon 
for basic monitoring of a linux server processes, cpu usage, 
network connections, ram usage, disk usage, file changes, etc...

This software is licensed under the GPLv3 http://www.gnu.org/licenses/

### Features

* Monitoring of file changes.
* Monitoring of servers online status.
* Monitoring of cpu, memory and disk usage.
* Monitoring of system processes/services status.
* Automatic restart of system processes/services if they fail.
* E-mailing of reports for system events like failed proccesses, 
  dead connections, file changes, critical cpu usage,
  critical memory usage, critical disk space usage, etc...

## Installation

As root user execute the following commands:

```shell
wget https://github.com/jgmdev/watchsys/archive/master.zip
unzip master.zip
cd watchsys-master
./install.sh
```

## Uninstallation

As root user execute the following commands:

```shell
cd watchsys-master
./uninstall.sh
```

## Usage

The installer will automatically detect if your system supports
init.d scripts, systemd services or cron jobs. If one of them is found
it will install apropiate files and start the watchsys script.

Once you hava WatchSys installed proceed to modify the config
files to fit your needs.

**/etc/watchsys/watchsys.conf**

The behaviour of the watchsys script is modified by this configuration file.
For more details see **man watchsys** which has documentation of the
different configuration options.

**/etc/watchsys/proc.list**

On this file you can add a list of processes you wish to monitor
in case of failure, this processes would be restarted by WatchSys
and a notification e-mail sent to you. Example:

> \# [Process Name] : [Service Name] : [Start Command] <br />
>   named          :   bind9        :  default <br />
>   hiawatha       :   hiawatha     :  hiawatha -c /custom/config.conf

**/etc/watchsys/servers.list**

On this file you can add a list of host names or ip addresses to 
monitor its online status, for example:

> \# server : port <br />
> myserver.com : none <br />
> myserver.com : 80 <br />
> mail.myserver.com : 143 <br />
> 192.168.1.1 : none

As you see **none** is used when we want to monitor a server online
status, but not a service on a specific port.

**/etc/watchsys/dir.list**

Here you can add a list of directories to scan for file changes.
if any changes are found on the given directories, an e-mail
will be sent to you with a report. Example:

> /usr/bin <br />
> /usr/sbin

After you modify the config files you will need to restart the daemon.
If running on systemd:

> systemctl restart watchsys

If running as classical init.d script:

> /etc/init.d/watchsys restart <br />
> or <br />
> service watchsys restart

## CLI Usage

**watchsys** [OPTION]

#### OPTIONS

**-h | --help:**

   Show the help screen.
    
**-d | --start:**

   Initialize a daemon to monitor connections.
    
**-s | --stop:**

   Stop the daemon.
    
**-t | --status:**

   Show status of daemon and pid if currently running.
