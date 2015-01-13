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

monitor_services

exit 0
