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
salt-call state.sls virl.routervms.all

# get all VM Maestro images
echo "installing VM Maestro images"
salt-call state.sls virl.vmm.vmmall

# DHCP server on guest not working reliably: 
# also requires no guest account in virl.ini for the workaround to work
# guest_account: False
# this is a workaround (FIXME)
# PS1=xxx is needed, otherwise .bashrc will exit right away and no OS_* variables
# are defined.
su -lc 'PS1=xxx; . ~/.bashrc; virl_uwm_client --username uwmadmin --password password project-create --name guest --user-password guest' virl

# add external nameservers to guest network
su -lc 'PS1=xxx; . ~/.bashrc; neutron subnet-update guest --dns_nameservers list=true 8.8.8.8 8.8.4.4' virl

# VMM connects to interface w/ default route (external interface)
# in this case we want it to show the internal interface
crudini --set /etc/virl/virl.cfg env virl_local_ip 172.16.1.1
crudini --set /etc/virl/virl.cfg env virl_std_process_count 20

# restart openstack services (to avoid a restart)
# echo "restarting OpenStack services"
# salt-call state.sls openstack-restart

# to make the changes in virl.cfg effective we need to restart STD
# (or restart the box, but this is the lesser of two evils)
echo "restarting STD..."
service virl-std restart

# clean up stuff as the last thing to do
cho "cleaning up stuff..."
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y

exit $STATE_OK

