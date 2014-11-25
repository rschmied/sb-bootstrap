#!/bin/bash
# 
# this installs the VM images
# if this is the final stage:
# restart required after this stage (exit=1)
#

PATH=/usr/sbin:/usr/bin:/sbin:/bin

ORIGIN=$(dirname $(readlink -f $0))
. ${ORIGIN}/../etc/config

# this is done as root
cd /home/virl/virl-bootstrap

# before we continue
while [[ $(sudo salt-call test.ping) =~ False ]]; do
  echo "no Salt connectivity ... sleeping 10s"
  sleep 10
done

# install the router VMs (lengthy)
salt-call state.sls routervms

# restart openstack services (to avoid a restart)
salt-call state.sls openstack-restart

exit 0

