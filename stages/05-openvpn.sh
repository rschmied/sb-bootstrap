#!/bin/bash
# 
# This installs OpenVPN plus certificates.
# Resulting client config files in CFG_VPN_CONF from config
#
#set -x

cd $(dirname $0)
. ../etc/common.sh

#
# get the IPv4 address of the interface with the default route
#
function default_ipv4 () {
  iface=$(ip route | awk '/^default / { for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; }}}')
  echo $(ifconfig $iface | sed -rn 's/.*r:([^ ]+) .*/\1/p')
}

#
# print the certificate given in $2
# wrap in tags provided in $1
# (note that END is a perfectly valid sequence in a key
# so the BEGIN and END patterns must be specific!)
#
function print_cert () {
  echo "<$1>"
  cat $2 | sed -n '/^-----BEGIN .*-----$/,/^-----END .*-----$/p'
  echo "</$1>"
}

#
# install required packages
#
apt-get -y install  openvpn easy-rsa


#
# certificate / CA stuff
#
cd /usr/share/easy-rsa/

sed -ri 's/(^export KEY_CITY=")(.*)"/\1San Jose"/' ./vars
sed -ri 's/(^export KEY_OU=")(.*)"/\1DevNet Sandbox"/' ./vars
sed -ri 's/(^export KEY_ORG=")(.*)"/\1Cisco"/' ./vars
sed -ri 's/(^export KEY_EMAIL=")(.*)"/\1root@'${CFG_HOSTNAME}.${CFG_DOMAIN}'"/' ./vars
sed -ri 's/(^export KEY_EXPIRE=)(.*)/\1365/' ./vars
sed -ri 's/(^export CA_EXPIRE=)(.*)/\1365/' ./vars

. ./vars
./clean-all
./pkitool --initca
./pkitool --server ${CFG_HOSTNAME}.${CFG_DOMAIN}
./pkitool          virl-sandbox-client
./build-dh

cd keys/
cp ca.crt ${CFG_HOSTNAME}.${CFG_DOMAIN}.* dh*.pem  /etc/openvpn/


#
# create the server config file
# (duplicate-cn allows the cert to be used multiple times)
#
cat >/etc/openvpn/server.conf <<EOF
port $CFG_VPN_PORT
proto $CFG_VPN_PROT
dev $CFG_VPN_DEV
duplicate-cn
ca /etc/openvpn/ca.crt
dh /etc/openvpn/dh2048.pem
key /etc/openvpn/${CFG_HOSTNAME}.${CFG_DOMAIN}.key
cert /etc/openvpn/${CFG_HOSTNAME}.${CFG_DOMAIN}.crt
max-clients 20
keepalive 10 60
persist-tun
verb 1
mute 3
push "route 172.16.0.0 255.255.252.0"
EOF

## push "dhcp-option DNS 8.8.8.8"
## push "dhcp-option DOMAIN virl.lab"

# 
# the networks here must match IP networks defined in /etc/virl.ini
# also different start procedure required for tap vs tun
#
if [[ $CFG_VPN_DEV =~ tun ]]; then
  echo "server 172.16.4.0 255.255.255.0" >>/etc/openvpn/server.conf
  ufw allow in on $CFG_VPN_DEV
else
  echo "server-bridge 172.16.1.1 255.255.255.0 172.16.1.32 172.16.1.48" >>/etc/openvpn/server.conf
  echo "up /etc/openvpn/bridge-up.sh" >>/etc/openvpn/server.conf

  cat >/etc/openvpn/bridge-up.sh <<EOF
#!/bin/bash
#
# If using a bridged interface, some more stuff is required.
# The bridge will be attached to FLAT == dummy1 interface.
#
# First, get the L3 interface attached to FLAT.
# It might take a while until Neutron brings it up so we wait for it.
#
# \$1 = tap_dev 
# \$2 = tap_mtu
# \$3 = link_mtu 
# \$4 = ifconfig_local_ip 
# \$5 = ifconfig_netmask 
# \$6 = [ init | restart ]
#

flat=""
while [ "\$flat" = "" ]; do
  flat=\$(brctl show | sed -rne '/dummy1/s/^(brq[a-z0-9\-]{11}).*dummy1$/\1/p')
  if [ "\$flat" = "" ]; then
  	echo "OpenVPN: waiting for FLAT bridge to come up..."
  	sleep 5
  fi
done

# add the VPN Tap device to the Bridge
brctl addif \$flat \$1

# bring the VPN Tap device up
ifconfig \$1 up mtu \$2

# make sure that the bridge interfaces are not subject
# to iptables filtering
sysctl -w net.bridge.bridge-nf-call-iptables=0
sysctl -w net.bridge.bridge-nf-call-ip6tables=0

# add the bridge to iptables
ufw allow in on \$flat

exit
EOF
  # make it executable
  chmod u+x /etc/openvpn/bridge-up.sh
fi


#
# client config file
#
cat >$CFG_VPN_CONF <<EOF
#  VIRL OpenVPN Client Configuration
client
dev $CFG_VPN_DEV
port $CFG_VPN_PORT
proto $CFG_VPN_PROT
persist-tun
verb 2
mute 3
nobind
reneg-sec 604800
# sndbuf 100000
# rcvbuf 100000

# Verify server certificate by checking
# that the certicate has the nsCertType
# field set to "server".  This is an
# important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the nsCertType
# field set to "server".  The build-key-server
# script in the easy-rsa folder will do this.
ns-cert-type server

# If you are connecting through an
# HTTP proxy to reach the actual OpenVPN
# server, put the proxy server/IP and
# port number here.  See the man page
# if your proxy server requires
# authentication.
;http-proxy-retry # retry on connection failures
;http-proxy [proxy server] [proxy port #]


EOF

# remaining config stuff
echo -n "remote " >>$CFG_VPN_CONF
default_ipv4 >>$CFG_VPN_CONF
print_cert "ca" ca.crt >>$CFG_VPN_CONF
print_cert "cert" virl-sandbox-client.crt >>$CFG_VPN_CONF
print_cert "key" virl-sandbox-client.key >>$CFG_VPN_CONF


# start OpenVPN service
# (if the server reboots after this step then this is not needed)
#service openvpn restart

exit $STATE_REBOOT

