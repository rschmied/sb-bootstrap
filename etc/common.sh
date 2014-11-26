#
# common variables and functions
#

# some paths
PATH=/usr/sbin:/usr/bin:/sbin:/bin
STAGES="stages"

# return states for stage scripts
STATE_OK=0
STATE_REBOOT=1
STATE_FATAL=-1

# configurable things
CFG_MAXWAIT=12
CFG_SLEEP=10
CFG_DOMAIN=virl.lab
CFG_LOGDIR=/root
CFG_HOSTNAME=$(hostname)
CFG_VPN_CONF=/home/virl/vpn-client.ovpn
CFG_VPN_DEV=tun0
CFG_VPN_PORT=443
CFG_VPN_PROT=tcp
CFG_SSH_PORT=22



# make sure we are connected to the master
# before we continue
# this will sleep forever if there's something wrong
# with the key / connectivity
# and it won't continue :)

function wait_for_salt () {
  waited=0
  while [[ $(sudo salt-call test.ping) =~ False ]]; do
    echo "no Salt connectivity ... sleeping 10s"
    sleep $CFG_SLEEP
    waited=$(($waited+1))
    if [[ $waited = $CFG_MAXWAIT ]]; then
      echo "Bail out, serious Salt connectivity problem!"
      exit $STATE_FATAL
    fi
  done
}
