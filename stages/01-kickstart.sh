#!/bin/bash
#
# do initial preparations for VIRL installationn
# - create required user
# - get the bootstrap repo from Git hub
# - prepare / install the required Salt keys
# - prepare / modify the virl.ini
# - do ZERO, SALT & FIRST
# - help with the network interfaces
# 
# reboot will be needed but done after installing
# the firewall (next step).
#
#set -x

cd $(dirname $0)
. ../etc/common.sh 

# add our hostname to localhost
sed -i 's/^127.0.0.1 localhost$/& '$CFG_HOSTNAME' '$CFG_HOSTNAME'.'$CFG_DOMAIN'/' /etc/hosts

# create the VIRL user 'virl'
# we don't want a password (use the root key instead)
useradd -m virl
usermod -a -G sudo virl
# standard cloud image has an ubuntu user
# on Rackspace, it is the root user
if [ -d /home/ubuntu ]; then
  cp -R /home/ubuntu/.ssh/ /home/virl/
else
  cp -R /root/.ssh/ /home/virl/
fi
chown -R virl.virl /home/virl/.ssh/

# move virl.ini to its place
cp ../etc/virl.ini /etc/

# need crudini upfront
apt-get -y install crudini

# swap the key ID and domain in virl.ini
SALT_DOMAIN=$(basename /tmp/*.pem | cut -d. -f2,3)
SALT_ID=$(basename /tmp/*.pem | cut -d. -f1)
crudini --set /etc/virl.ini DEFAULT salt_master "$CFG_SALTMASTER"
crudini --set /etc/virl.ini DEFAULT salt_id $SALT_ID
crudini --set /etc/virl.ini DEFAULT salt_domain $SALT_DOMAIN
crudini --set /etc/virl.ini DEFAULT hostname $CFG_HOSTNAME
crudini --set /etc/virl.ini DEFAULT domain $CFG_DOMAIN


# clone the VIRL boot strap
# forked from 
# https://github.com/VIRL-Open/virl-bootstrap.git

su -c "git clone https://github.com/rschmied/virl-bootstrap.git" - virl
if [ ! -x /home/virl/virl-bootstrap/virl-bootstrap.py ]; then
  echo "no VIRL bootstrap repo from Git available!"
  echo "Bail out, serious Salt connectivity problem!"
  exit $STATE_FATAL
fi

# now as root
# copy and prep private
# bootstrap the salt minion
cd /home/virl/virl-bootstrap

# do the salt minion pub/private key stuff
#
mkdir -p /etc/salt/pki/minion
cp ./master_sign.pub /etc/salt/pki/minion
rm -f ./preseed_keys/minion.pem
cp /tmp/*.pem ./preseed_keys/minion.pem
openssl rsa -in ./preseed_keys/minion.pem -pubout >./preseed_keys/minion.pub
cp -f ./preseed_keys/minion.pem /etc/salt/pki/minion/minion.pem
cp -f ./preseed_keys/minion.pub /etc/salt/pki/minion/minion.pub
chmod 400 /etc/salt/pki/minion/minion.pem

#
# write the /etc/salt/minion.d/extra.conf
#
mkdir -p /etc/salt/minion.d/
cat >/etc/salt/minion.d/extra.conf <<EOF
master: [ $CFG_SALTMASTER ]
id: $SALT_ID
append_domain: $SALT_DOMAIN
master_type: failover 
verify_master_pubkey_sign: True 
master_shuffle: True 
master_alive_interval: 180 
EOF

#
# install Salt
#
sh /home/virl/virl-bootstrap/bootstrap-salt.sh stable
if [[ $(salt-minion --version) =~ ^salt-minion\ 2014.7.0.*\ \(Helium\)$ ]]; then 
  echo "Expected Salt Version 2014.7.0 Helium installed"
else
  echo "Salt version not correct... trying to rectify..."
  apt-get update && apt-get upgrade salt-minion salt-common -y
  echo "Check what we have now:"
  salt-minion --version
fi

# check that Salt is available and key is OK
wait_for_salt

# make a backup of the interface configuration!
cp /etc/network/interfaces /root/interfaces

# do ZERO
salt-call state.sls zero

# install salt stuff
if [ -f /etc/salt/grains ]; then
  rm /etc/salt/grains
fi
/usr/local/bin/vinstall salt

# install FIRST
sleep 5 
/usr/local/bin/vinstall first

# need to take care of the interface changes...
# before we reboot ;)
mv /etc/network/interfaces /etc/network/interfaces-virl
cp /root/interfaces /etc/network/interfaces
cat /etc/network/interfaces-virl | \
  sed -e '/^auto lo/d;/^iface lo inet loopback/d' \
  >>/etc/network/interfaces

# reboot required after FW is in place (next step)

exit $STATE_OK

