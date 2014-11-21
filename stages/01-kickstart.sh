#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin

ORIGIN=$(dirname $(readlink -f $0))
. ${ORIGIN}/../etc/config

# add our hostname to localhost
# sed -i 's/^127.0.0.1 localhost$/& '$MY_HOSTNAME' '$MY_HOSTNAME'.'$DOMAIN'/' /etc/hosts

# create the VIRL user 'virl'
# we don't want a password (use the root key instead)
useradd -m virl
usermod -a -G sudo virl
cp -R /home/ubuntu/.ssh/ /home/virl/
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
openssl rsa -in ./preseed_keys/minion.pem  -pubout > ./preseed_keys/minion.pub
cp -f ./preseed_keys/minion.pem /etc/salt/pki/minion/minion.pem
cp -f ./preseed_keys/minion.pub /etc/salt/pki/minion/minion.pub
chmod 400 /etc/salt/pki/minion/minion.pem
sh /home/virl/virl-bootstrap/bootstrap-salt.sh git 2014.7

# make sure we are connected to the master
# before we continue
if [[ $(sudo salt-call test.ping) =~ True ]]; then 

  # make a backup of the interface configuration!
  cp /etc/network/interfaces /root/interfaces

  # do ZERO
  sudo salt-call state.sls zero

  # swap the key ID and domain in virl.ini
  cp ${ORIGIN}/../etc/virl.ini /etc/
  SALT_DOMAIN=$(basename /tmp/*.pem | cut -d. -f2,3)
  SALT_ID=$(basename /tmp/*.pem | cut -d. -f1)
  crudini --set /etc/virl.ini DEFAULT salt_id $SALT_ID
  crudini --set /etc/virl.ini DEFAULT salt_domain $SALT_DOMAIN
  crudini --set /etc/virl.ini DEFAULT hostname $MY_HOSTNAME
  crudini --set /etc/virl.ini DEFAULT domain $DOMAIN

  # need to take care of the interface changes...
  mv /etc/network/interfaces /etc/network/interfaces-virl
  cp /root/interfaces /etc/network/interfaces
  cat /etc/network/interfaces-virl >>/etc/network/interfaces

  # after this, it's time for a reboot
  # e.g. first stage is done!

else

  cat <<EOF
	####################
        salt master problem
        ####################
EOF

fi


exit

