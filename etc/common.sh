#
# common variables and functions
#

# define path
PATH=/usr/sbin:/usr/bin:/sbin:/bin

# defines some return states for stage scripts
STATE_OK=0
STATE_REBOOT=1
STATE_FATAL=-1

# how many known Salt states that fail?
CFG_MAX_FAIL=2


#######################################
# configurable things below with CFG_ #
#######################################

# if Salt is not available. How often and for how long
# do we wait until we give up? 12*10 = 120s = 2min
CFG_MAXWAIT=12
CFG_SLEEP=10

# hostname / domain settings
CFG_DOMAIN=virl.lab
CFG_HOSTNAME=$(hostname)

# where do the install log files go?
CFG_LOGDIR=/root

# which port does SSH listen on?
# (also configures firewall)
CFG_SSH_PORT=22

# this is where the resulting client config file will be written
CFG_VPN_CONF=/home/virl/vpn-client.ovpn

# what VPN device are we using?
# tun0 --> L3 VPN, CFG_VPN_L3_NET needs to be defined
# tap0 --> L2 VPN, CFG_VPN_L2_LO and CFG_VPN_L2_HI needs to be defined
CFG_VPN_DEV=tun0

# Port number and Protocol (udp/tcp) for OpenVPN 
CFG_VPN_PORT=443
CFG_VPN_PROT=tcp

# if we use L3 VPN, this needs to be defined
CFG_VPN_L3_NET=172.16.4.0/24

# if we use L2 VPN, we bridge the VPN clients into the FLAT network
# LO and HI define the IP addresses in that network that will be used
# for the VPN clients. DHCP pool usually starts at .50
# This assumes that the FLAT network is a /24 and that the
# LO and HI values define a range in the 4th IP octet.
CFG_VPN_L2_LO=20
CFG_VPN_L2_HI=39

# what route do we want to push to the VPN client?
# should contain a supernet of all networks used internally
# on the VIRL host.
CFG_VPN_ROUTE=172.16.0.0/22


#
# make sure we are connected to the master
# before we continue (e.g key and connectivity are OK)
# this will sleep as defined above in SLEEP and MAXWAIT
# if time's up it will return STATE_FATAL and the installation
# will abort!
#
function wait_for_salt () {
  waited=0
  while [[ $(sudo salt-call test.ping) =~ False ]]; do
    echo "no Salt connectivity ... sleeping ${CFG_SLEEP}s"
    sleep $CFG_SLEEP
    waited=$(($waited+1))
    if [[ $waited = $CFG_MAXWAIT ]]; then
      echo "Bail out, serious Salt connectivity problem!"
      exit $STATE_FATAL
    fi
  done
}

