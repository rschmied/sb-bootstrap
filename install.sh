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
. etc/config  
  
#
# get the next step in the sequence
#
function get_step() {
  echo $(ls $STAGES/??-* 2> /dev/null | head -1 | sed -e 's/.*\///')  
}
  
DONE=0
while [[ $DONE == 0 ]]; do
  STEP=$(get_step)
  if [ "$STEP" != "" ]; then
    echo  
    echo "Executing step: "  $STEP
    echo "=============================================================================="  
    echo  
    echo -n "Start: "; date
    TIME_START=$(date +"%s")
    $STAGES/$STEP >${LOGDIR}/${STEP}.log 2>&1 
    BOOT_NEEDED=$?
    echo -n "Done:  "; date;
    TIME_DONE=$(date +"%s")
    TIME_DIFF=$(($TIME_DONE-$TIME_START))
    echo "$(($TIME_DIFF / 60)) min $(($TIME_DIFF % 60)) sec"
    mv $STAGES/$STEP $STAGES/done-$STEP
    STEP=$(get_step)
  fi  
    
  #  
  # Check if this was the last step. 
  # If it was, make sure we are never invoked again.  
  #  
  if [ "$STEP" = "" ]  
  then  
    echo  
    echo "No more steps -- removing us from rc.local"  
    echo "=============================================================================="  
    echo  
    sed -i 's/.*###BOOTSTRAP###$/exit 0/' /etc/rc.local  
    DONE=1
  fi  

  #
  # if the reboot flag is set
  # do a reboot, otherwise just stop
  #
  if [[ $BOOT_NEEDED > 0 ]]; then
    DONE=1
    echo "Rebooting in 10 seconds..."
    sleep 10  
    reboot  
  fi

done
