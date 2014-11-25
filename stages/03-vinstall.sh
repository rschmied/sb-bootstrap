#!/bin/bash
# 
# this installs all the remaining VIRL stuff
# no restart required after this stage (exit=0)
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

# do all the other VIRL install stages
/usr/local/bin/vinstall all

exit 0

