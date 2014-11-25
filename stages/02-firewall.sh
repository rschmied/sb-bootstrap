#!/bin/bash
#
# This sets up the User Friendly Firewall (UFW)
# SSH and OpenVPN traffic IN
# VIRL Networks NAT OUT
#
# set -x

cd $(dirname $0)
. ../etc/config

# 
# change default forward policy from 'DROP' to 'ACCEPT'
#
sed -ri 's/(^DEFAULT_FORWARD_POLICY=")(.*)"/\1ACCEPT"/' /etc/default/ufw


#
# change the SSH port, if needed
#
if [ "$CFG_SSH_PORT" != "22" ]; then
  echo "Changing SSH port to $CFG_SSH_PORT"
  sed -ri 's/(^Port )(.*)/\1'$CFG_SSH_PORT'/' /etc/ssh/sshd_config
  service ssh restart
fi


#
# what is the external interface that holds the default route?
#
gw=$(ip route | awk '/^default / { for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; }}}')

#
# on the external interface, allow SSH and OpenVPN
# the rules should go before filter
# there's apparently no easy way to insert those commands
# using the ufw CLI
# (added content runs to the COMMIT\n line)
#
sed -ie "/^\*filter/i\
*nat\n\
:POSTROUTING ACCEPT [0:0]\n\
\n\
# Forward traffic through $gw\n\
-A POSTROUTING -s 172.16.0.0/22 -o $gw -j MASQUERADE\n\
-A POSTROUTING -s 172.16.4.0/24 -o $gw -j MASQUERADE\n\
\n\
# don't delete the 'COMMIT' line or these nat table rules won't\n\
# be processed\n\
COMMIT\n" /etc/ufw/before.rules


#
# regular UFW rules (not NAT)
#
ufw allow in on $gw to any port $CFG_SSH_PORT proto tcp
ufw allow in on $gw to any port $CFG_VPN_PORT proto $CFG_VPN_PROT

# sudo grep '^### tuple' /lib/ufw/user*.rules

#
# enabling the FW will make it persistent
# across reboots!
#
echo "y" | ufw enable

# after this, it's time for a reboot
# e.g. first stage and firewall is done!

exit 1


