#!/bin/bash
#
# - expects usable KEYs in KEYDIR
# - moves used keys to KEYDIR/USEDKEYS
# - expects user-data (minus key) in TOP
# - user data should have "write_files:" (and 
#   potentially some other files) already included
# - will add the key file from a KEY to user-data
# - will take a list of users from the command line
# - will boot a machine for each (user, key) 
#
#set -x

TOP="./user-data-static"
KEYDIR="KEYS/keys-pool/"
USEDKEYS="$KEYDIR/USEDKEYS/"

# Bare Metal
FLAVOR=onmetal-compute1
IMAGE=06bb130b-7607-46f9-85ae-124bae4d0f5b

# PVPHV 
#FLAVOR=6
#IMAGE=a3ba4cf5-70b9-4805-afa2-30d1ab81a625

cd $(dirname $0)

if [ $# -lt 1 ]; then
	echo "username list required as parameters"
	exit
fi


for user in $*; do
	userkey=$(basename 2>/dev/null $(ls 2>/dev/null -r $KEYDIR/*.pem | head -1 ))
	if [ "$userkey" == "" ]; then
		echo "no usable key found"
		exit
	fi
	userdata=$(mktemp -t ${user}-data-)
	cat $TOP >>$userdata
	echo "- path: /tmp/"$userkey >>$userdata
	echo "  owner: root:root" >>$userdata
	echo "  content: |" >>$userdata
	cat $KEYDIR/$userkey | sed 's/^/    /' >>$userdata
	echo :  permissions: '0444'" >>$userdata

	keynum=$(echo $userkey | sed  -nE "s/^.*([0-9A-F]{8}).*$/\1/p")

	# echo "MANUAL_VIRL_${user}_${keynum}"
	nova boot --flavor $FLAVOR \
          --image $IMAGE \
          --key-name some-ssh-key-name \
          --meta i_was_born=$(date -u +%s) \
          --config-drive=true \
          --user-data $userdata \
          MANUAL_VIRL_${user}_${keynum}

    mv $KEYDIR/$userkey $USEDKEYS
    rm $userdata

done


exit

