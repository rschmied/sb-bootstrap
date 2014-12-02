#!/bin/bash
#  
# This install script executes all scripts in the stages directory
# they need to be named 00-something.sh ([0-9]{2}-)
# Exit status of the stages script is either 
# - 0 (no reboot needed) 
# - 1 (reboot needed)
# if no more stages are found, the script will remove the script
# invocation from /etc/rc.local (where it has been installed 
# during initial bootstrap)
#  
#set -x

PATH=/usr/sbin:/usr/bin:/sbin:/bin

cd $(dirname $0)
. etc/common.sh  
  
#
# get the next step in the sequence
#
function get_step() {
  echo $(ls stages/??-* 2> /dev/null | head -1 | sed -e 's/.*\///')  
}

#
# print a time difference
# $1 is the start time
# $2 is the current time
# $3 is a label
#
function print_timediff() {
  TIME_DIFF=$(($2-$1))
  echo "$3 $(($TIME_DIFF / 60)) min $(($TIME_DIFF % 60)) sec"
}
  
#
# get the start time of this VM via Cloud Init meta data
#
TIME_BORN=$(./born.py)

DONE=0
BOOT_NEEDED=0
while [[ $DONE == 0 ]]; do
  STATE=$STATE_OK
  STEP=$(get_step)
  if [ "$STEP" != "" ]; then
    echo  
    echo "Executing step: "  $STEP
    echo "=============================================================================="  
    echo  
    echo -n "Start: "; date
    TIME_STEP=$(date +"%s")

    # execute the step and get the return state
    stages/$STEP >${CFG_LOGDIR}/${STEP}.log 2>&1 
    STATE=$?

    # sh -c "/bin/egrep -nr '^Failed:\s+[^0][1-9]+' 03-vinstall.sh.log "

    echo -n "Done:  "; date
    TIME_NOW=$(date +"%s")
    print_timediff $TIME_STEP $TIME_NOW "For step  :"
    print_timediff $TIME_BORN $TIME_NOW "Since born:"

    # did the stage go well?
    if [[ $STATE == $STATE_FATAL ]]; then
      echo "**** FATAL  ERROR ****"
      echo "check state log files!"
      DONE=1
      STEP=""
    else
      # disable current step and get the next step (if any)
      mv stages/$STEP stages/done-$STEP
      STEP=$(get_step)
    fi
  fi  
    
  #  
  # Check if there are no more steps to execute -and-
  # there is no pending reboot...
  # If yes: Make sure we are never invoked again.  
  #  
  if [[ "$STEP" == "" && $STATE != $STATE_REBOOT ]]; then
    echo  
    echo "No more steps -- removing us from rc.local"  
    echo "=============================================================================="  
    echo  
    sed -i 's/.*###BOOTSTRAP###$/exit 0/' /etc/rc.local  
    TIME_NOW=$(date +"%s")
    print_timediff $TIME_BORN $TIME_NOW "Total time to install:"
    DONE=1

    #
    # Check for failed Salt states
    # we expect it to be less or equal than CFG_MAX_FAIL 
    #
    fails=0
    failed=$(sed -nre '/Failed:\s+/s/(^Failed:\s+)([0-9]+)/\2/p' ${CFG_LOGDIR}/??-*.log)
    for num in $failed; do
      fails=$(( $fails + $num ))
    done
    if [ $fails -gt $CFG_MAX_FAIL ]; then 
      echo "**** SALT   ERROR ****"
      echo "check state log files!"
    fi

  fi  

  #
  # if the reboot flag is set
  # do a reboot, otherwise just stop
  #
  if [ $STATE -eq $STATE_REBOOT ]; then
    DONE=1
    echo "Rebooting in 10 seconds..."
    sleep 10  
    reboot  
  fi

done

