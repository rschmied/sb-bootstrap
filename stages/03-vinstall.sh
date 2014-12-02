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

# Since MySQL binds to the cluster interface
# (and not to the loopback anymore thanks to
# VIRLDEV-669) that interface needs to be up 
# unless we reboot (which we don't).
ifup dummy4

# do all the other VIRL install stages
echo "install all remaining VIRL packages"
/usr/local/bin/vinstall all

# packages which are present (and required) in standard
# Ubuntu server install but are missing on Rackspace.
echo "install one-off packages"
apt-get install ethtool

exit $STATE_OK

