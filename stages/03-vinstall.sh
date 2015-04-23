#!/bin/bash
# 
# this installs all the remaining VIRL stuff
# no restart required after this stage (exit=0)
#
#set -x

cd $(dirname $0)
. ../etc/common.sh 

# this is done as root
cd /home/virl/virl-bootstrap

# check that Salt is available and key is OK
wait_for_salt

# packages which are present (and required) in standard
# Ubuntu server install but are missing on Rackspace.
#
# ethtool required by LXC container --> "Fix Container"
# gawk required to make apparmor happy for the telnet_front thing
echo "install one-off packages"
apt-get install -y ethtool gawk

#apt-get install -y ethtool libffi-dev openstack-dashboard nova-api python-neutronclient

# do all the other VIRL install stages
echo "install all remaining VIRL packages"
/usr/local/bin/vinstall all

# fix Linux bridging (only temporary needed, should go into all eventually)
/usr/local/bin/vinstall bridge

# fix the bind port in nova.conf
# otherwise it will listen on the outside, public facing IP which is firewalled)
echo "configuring nova.conf"
crudini --set /etc/nova/nova.conf DEFAULT serial_port_proxyclient_address 172.16.1.1

exit $STATE_OK

