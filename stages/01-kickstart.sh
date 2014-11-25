#!/bin/bash
#
# restart required after this stage (exit=1)
#
#set -x

cd $(dirname $0)
. ../etc/config  

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

# clone the VIRL boot strap
su -c "git clone https://github.com/VIRL-Open/virl-bootstrap.git" - virl

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
sh /home/virl/virl-bootstrap/bootstrap-salt.sh git 2014.7

# make sure we are connected to the master
# before we continue
# this will sleep forever if there's something wrong
# with the key / connectivity
# and it won't continue :)
while [[ $(sudo salt-call test.ping) =~ False ]]; do
  echo "no Salt connectivity ... sleeping 10s"
  sleep 10
done

# make a backup of the interface configuration!
cp /etc/network/interfaces /root/interfaces

# do ZERO
salt-call state.sls zero

# swap the key ID and domain in virl.ini
cp ../etc/virl.ini /etc/
SALT_DOMAIN=$(basename /tmp/*.pem | cut -d. -f2,3)
SALT_ID=$(basename /tmp/*.pem | cut -d. -f1)
crudini --set /etc/virl.ini DEFAULT salt_id $SALT_ID
crudini --set /etc/virl.ini DEFAULT salt_domain $SALT_DOMAIN
crudini --set /etc/virl.ini DEFAULT hostname $CFG_HOSTNAME
crudini --set /etc/virl.ini DEFAULT domain $CFG_DOMAIN

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

exit 0

