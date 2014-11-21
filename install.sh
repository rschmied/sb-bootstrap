#!/bin/bash
#  
# Find out where we are, and read our config file. From there we'll know all further  
# path names.  
#  
set -x

PATH=/usr/sbin:/usr/bin:/sbin:/bin

. $(dirname $0)/etc/config  
  
#
# get the next step in the sequence
#
function get_step() {
  echo $(ls $STAGES/??-* 2> /dev/null | head -1 | sed -e 's/.*\///')  
}
  
#
# if there are steps left in the stages directory we are not done yet
# exechute the next step
#
STEP=$(get_step)
if [ "$STEP" != "" ]; then
  echo  
  echo "Executing step: "  $STEP
  echo "=============================================================================="  
  echo  
  $STAGES/$STEP 2>&1 | tee -a $LOGFILE  
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
  # sed -i 's/.*###BOOTSTRAP###$/exit 0/' /etc/rc.local  
  # rm -fr $STAGE_DIR  
fi  
  
echo rebooting in 60 seconds  
sleep 60  
reboot  
