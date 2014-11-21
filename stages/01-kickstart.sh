#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin

. $(dirname)/../etc/config

# create the VIRL user 'virl'
# we don't want a password (use the root key instead)
usermod -a -G sudo virl
cp -R /root/.ssh/ /home/virl/
chown -R virl.virl /home/virl/.ssh/

# clone the VIRL boot strap
su -c "git clone https://github.com/VIRL-Open/virl-bootstrap.git" - virl 2>&1 | \
      tee -a $LOGFILE

exit

