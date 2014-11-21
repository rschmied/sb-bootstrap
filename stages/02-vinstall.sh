#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin

ORIGIN=$(dirname $(readlink -f $0))
. ${ORIGIN}/../etc/config

# now as root
# copy and prep private
# bootstrap the salt minion
cd /home/virl/virl-bootstrap

# before we continue
while [[ $(sudo salt-call test.ping) =~ False ]]; do
  echo "no Salt connectivity ... sleeping 10s"
  sleep 10
done

# do the first stage installation
/usr/local/bin/vinstall all

exit

