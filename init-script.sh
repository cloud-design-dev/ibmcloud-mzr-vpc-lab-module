#!/bin/bash
# disable the auto update
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service

# wait until `apt` has been killed and locks released
while ! (systemctl list-units --all apt-daily.service | egrep -q '(dead|failed)')
do
  sleep 1;
done

## update the package list
DEBIAN_FRONTEND=noninteractive apt-get -qqy update
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -y linux-headers-$(uname -r) build-essential python3-pip curl wget unzip jq  
