#!/bin/bash
# 
# this installs the VM images
# if this is the final stage:
# restart required after this stage (exit=1)
#
#set -x

cd $(dirname $0)
. ../etc/common.sh  

# this is done as root
cd /home/virl/virl-bootstrap

# check that Salt is available and key is OK
wait_for_salt

# install the router VMs (lengthy)
echo "installing Cisco OS VM images"
salt-call state.sls routervms

# get all VM Maestro images
echo "installing VM Maestro images"
sudo salt-call state.sls virl.vmm.vmmall

# do some misc modification before restarting OpenStack services
echo "doing misc settings"
su -lc 'PS1=xxx; . ~/.bashrc; neutron subnet-update guest --dns_nameservers list=true 8.8.8.8 8.8.4.4' virl
crudini --set /etc/virl/virl.cfg env virl_local_ip 172.16.1.1

# restart openstack services (to avoid a restart)
echo "restarting OpenStack services"
salt-call state.sls openstack-restart

exit $STATE_OK

