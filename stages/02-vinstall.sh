#!/bin/bash
# 
# no restart required after this stage (exit=0)
#

PATH=/usr/sbin:/usr/bin:/sbin:/bin

ORIGIN=$(dirname $(readlink -f $0))
. ${ORIGIN}/../etc/config

# now as root
# copy and prep private
# bootstrap the salt minion
cd /home/virl/virl-bootstrap

# before we continue
while [[ $(sudo salt-call test.ping) =~ False ]]; do
  echo "no Salt connectivity ... sleeping 10s"
  sleep 10
done

# do all the other VIRL install stages
/usr/local/bin/vinstall all

# install the router VMs (lengthy)
salt-call state.sls routervms

exit 1

