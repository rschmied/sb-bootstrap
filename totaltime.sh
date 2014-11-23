#!/bin/bash

UPTIME=$(date -d "$(uptime -s)" +%s)
DIFF=$(($UPTIME - $(./born.py)))
echo "$(($DIFF / 60)) min $(($DIFF % 60)) sec"

