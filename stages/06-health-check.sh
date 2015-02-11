#!/bin/bash
#
# check VIRL installation as the final step
# do various 'healt checks'
# - check strings are contained in virl_health_status
# - check Neutron agents
# - check OpenVPN status
# 
# return STATE_OK -or- STATE_FATAL
#
#set -x

cd $(dirname $0)
. ../etc/common.sh 

OK_STRINGS='MySQL is available
RabbitMQ configured for Nova is available
RabbitMQ configured for Glance and Neutron is available
OpenStack identity service for STD is available
OpenStack image service for STD is available
OpenStack compute service for STD is available
OpenStack network service for STD is available
STD server on url http://localhost:19399 is listening, server version [0-9\.]+$
UWM server on url http://localhost:19400 is listening, server version [0-9\.]+$
"product-expires": 7,
"kvm-ok": "INFO: /dev/kvm exists\\nKVM acceleration can be used"
"autonetkit-version": "autonetkit [0-9\.]+",'

IMAGES='CSR1000v
IOS XRv
IOSv
NX-OSv
server'



CHECK=0
OK=0
HEALTH=/usr/local/bin/virl_health_status
NEUTRON=/usr/bin/neutron
GLANCE=/usr/bin/glance
OPENVPN=/usr/sbin/openvpn
VPNCLIENTFILE=/home/virl/vpn-client.ovpn
VPNCLIENTLINES=131

# do checks against virl_health_status
if [ -x $HEALTH ]; then 
	TEMPFILE=$(mktemp -t health-XXXXXXXXXXX)
	chmod 666 $TEMPFILE
	su -lc "PS1=xxx; . ~/.bashrc; sudo $HEALTH >$TEMPFILE" virl
	while IFS= read -r line; do
		CHECK=$((CHECK + 1))
		if grep -Eqe "$line" $TEMPFILE ; then
			OK=$((OK + 1))
		else
			echo "*** No Match:" $line
		fi
	done <<<"$OK_STRINGS"
	rm $TEMPFILE
else
	CHECK=1
	echo "*** No virl_health_status"
fi

# check glance image list
if [ -x $GLANCE ]; then 
	TEMPFILE=$(mktemp -t glance-XXXXXXXXXXX)
	chmod 666 $TEMPFILE
	su -lc "PS1=xxx; . ~/.bashrc; $GLANCE image-list >$TEMPFILE" virl
	while IFS= read -r line; do
		CHECK=$((CHECK + 1))
		if grep -Eqe "$line.*active" $TEMPFILE ; then
			OK=$((OK + 1))
		else
			echo "*** No Image:" $line
		fi
	done <<<"$IMAGES"
	rm $TEMPFILE
else
	CHECK=1
	echo "*** No glance"
fi

# do specific Neutron checks
# (contained in virl_health_status but not single line checks)
if [ -x $NEUTRON ]; then
	CHECK=$((CHECK + 1))
	if [ $(su -lc "PS1=xxx; . ~/.bashrc; $NEUTRON agent-list -f csv" virl | grep '":-)",True' | wc -l) -eq 4 ]; then 
		OK=$((OK + 1))
	else
		echo "*** (some) Neutron Agents are missing"
	fi
else
	echo "*** no Neutron Agent found"
fi

# do specific OpenVPN checks
if [ -x $OPENVPN ]; then
	CHECK=$((CHECK + 1))
	if [[ "$(service openvpn status)" =~  " * VPN 'server' is running" ]]; then
		OK=$((OK + 1))
	else
		echo "*** VPN service inoperational"
	fi
else
	echo "*** no OpenVPN service found"
fi

# check OpenVPN client config file
if [ -f $VPNCLIENTFILE ]; then
	CHECK=$((CHECK + 1))
	if [ $(cat $VPNCLIENTFILE | wc -l) -eq $VPNCLIENTLINES ]; then 
		OK=$((OK + 1))
	else
		echo "*** VPN Client file has unexpected length"
	fi
else
	echo "*** no OpenVPN client config found"
fi

# if we have more checks than OKs then
# something's weird.
if [ $CHECK != $OK ]; then
	STATE=$STATE_FATAL
else
	STATE=$STATE_OK
fi

exit $STATE
