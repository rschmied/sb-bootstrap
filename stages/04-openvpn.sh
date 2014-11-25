#!/bin/bash
# 
# This installs OpenVPN plus certificates.
# Resulting client config files in VPNCLIENT_CONF from config
#

cd $(dirname $0)
. ../etc/config  

#
# get the IPv4 address of the interface with the default route
#
function default_ipv4 () {
  iface=$(ip route | awk '/^default / { for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; }}}')
  echo $(ifconfig $iface | sed -rn 's/.*r:([^ ]+) .*/\1/p')
}

#
# print the certificate given in $2 between
# --- BEGIN --- and --- END ---
# wrap in tags provided in $1
#
function print_cert () {
  echo "<$1>"
  cat $2 | sed -n '/BEGIN/,/END/p'
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
sed -ri 's/(^export KEY_EMAIL=")(.*)"/\1root@'${MY_HOSTNAME}.${DOMAIN}'"/' ./vars
sed -ri 's/(^export KEY_EXPIRE=)(.*)/\1365/' ./vars
sed -ri 's/(^export CA_EXPIRE=)(.*)/\1365/' ./vars

. ./vars
./clean-all
./pkitool --initca
./pkitool --server my-server
./pkitool          my-client
./build-dh

cd keys/
cp ca.crt my-server.* dh*.pem  /etc/openvpn/


#
# create the server config file
#
cat >/etc/openvpn/server.conf <<EOF
port $VPNCLIENT_PORT
proto $VPNCLIENT_PROT
dev $VPNCLIENT_DEV
ca   /etc/openvpn/ca.crt
cert /etc/openvpn/my-server.crt
key  /etc/openvpn/my-server.key
dh   /etc/openvpn/dh2048.pem
server 172.16.4.0 255.255.255.0
max-clients 20
keepalive 10 60
persist-tun
verb 1
mute 3
push "route 172.16.0.0 255.255.252.0"
EOF

## push "dhcp-option DNS 8.8.8.8"
## push "dhcp-option DOMAIN virl.lab"


cat >$VPNCLIENT_CONF <<EOF
#  VIRL OpenVPN Server
client
dev $VPNCLIENT_DEV
port $VPNCLIENT_PORT
proto $VPNCLIENT_PROT
persist-tun
verb 2
mute 3
nobind
reneg-sec 604800
sndbuf 100000
rcvbuf 100000
EOF

# remaining config stuff
echo -n "remote " >>$VPNCLIENT_CONF
default_ipv4 >>$VPNCLIENT_CONF
print_cert "ca" ca.crt >>$VPNCLIENT_CONF
print_cert "cert" my-client.crt >>$VPNCLIENT_CONF
print_cert "key" my-client.key >>$VPNCLIENT_CONF


# start OpenVPN service
service openvpn restart

exit 0

