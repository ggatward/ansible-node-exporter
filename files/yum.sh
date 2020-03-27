#!/bin/bash
#
# Description: Expose metrics from yum updates.
#
# Author: Slawomir Gonet <slawek@otwiera.cz>
#
# Based on apt.sh by Ben Kochie <superq@gmail.com>

set -u -o pipefail

# shellcheck disable=SC2016
filter_awk_script='
BEGIN { mute=1 }
/Obsoleting Packages/ {
  mute=0
}
mute && /^[[:print:]]+\.[[:print:]]+/ {
  print $3
}
'

check_upgrades() {
  /usr/bin/yum -q check-update |
    awk "${filter_awk_script}" |
    sort |
    uniq -c |
    awk '{print "yum_upgrades_pending{repo=\""$2"\"} "$1}'
}

upgrades=$(check_upgrades)

echo '# HELP yum_upgrades_pending Yum package pending updates by repo.'
echo '# TYPE yum_upgrades_pending gauge'
if [[ -n "${upgrades}" ]] ; then
  echo "${upgrades}"
else
  echo 'yum_upgrades_pending{repo=""} 0'
fi


echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [ $(/usr/bin/needs-restarting -r | echo $?) -ne 0 ] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi
