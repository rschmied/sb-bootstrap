#!/bin/bash
# 
# this installs the VM images
# if this is the final stage:
# restart required after this stage (exit=1)
#
#set -x

cd $(dirname $0)
. ../etc/config  

# this is done as root
cd /home/virl/virl-bootstrap

# before we continue
while [[ $(sudo salt-call test.ping) =~ False ]]; do
  echo "no Salt connectivity ... sleeping 10s"
  sleep 10
done

# install the router VMs (lengthy)
salt-call state.sls routervms

# do some misc modification before restarting OpenStack services
su -lc 'PS1=xxx; . ~/.bashrc; neutron subnet-update guest --dns_nameservers list=true 8.8.8.8 8.8.4.4' virl
crudini --set /etc/virl/virl.cfg env virl_local_ip 172.16.1.1

# restart openstack services (to avoid a restart)
salt-call state.sls openstack-restart

exit 0

