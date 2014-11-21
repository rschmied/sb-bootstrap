#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin

. $(dirname $0)/../etc/config

# add our hostname to localhost
sed -i 's/^127.0.0.1 localhost$/& '$(hostname)'/' /etc/hosts

# create the VIRL user 'virl'
# we don't want a password (use the root key instead)
useradd -m virl
usermod -a -G sudo virl
cp -R /root/.ssh/ /home/virl/
chown -R virl.virl /home/virl/.ssh/

# clone the VIRL boot strap
su -c "git clone https://github.com/VIRL-Open/virl-bootstrap.git" - virl 2>&1 | \
      tee -a $LOGFILE

# now as root
# copy and prep private
# bootstrap the salt minion
cd /home/virl/virl-bootstrap
mkdir -p /etc/salt/pki/minion
cp ./master_sign.pub /etc/salt/pki/minion
rm -f ./preseed_keys/minion.pem
mv /tmp/*.pem ./preseed_keys/minion.pem
openssl rsa -in ./preseed_keys/minion.pem  -pubout > ./preseed_keys/minion.pub
cp -f ./preseed_keys/minion.pem /etc/salt/pki/minion/minion.pem
cp -f ./preseed_keys/minion.pub /etc/salt/pki/minion/minion.pub
chmod 400 /etc/salt/pki/minion.pem
sh /home/virl/virl-bootstrap/bootstrap-salt.sh git 2014.7

exit

