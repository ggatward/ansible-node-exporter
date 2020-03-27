#!/bin/bash

set -u -o pipefail

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
  /usr/bin/dnf -q check-update |
    awk "${filter_awk_script}" |
    sort |
    uniq -c |
    awk '{print "dnf_upgrades_pending{repo=\""$2"\"} "$1}'
}

upgrades=$(check_upgrades)

echo '# HELP dnf_upgrades_pending DNF package pending updates by origin.'
echo '# TYPE dnf_upgrades_pending gauge'
if [[ -n "${upgrades}" ]] ; then
  echo "${upgrades}"
else
  echo 'dnf_upgrades_pending{repo=""} 0'
fi


echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [ $(/usr/bin/dnf needs-restarting -r | echo $?) -ne 0 ] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi
