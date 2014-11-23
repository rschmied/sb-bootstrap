#!/bin/bash

# 2g: --flavor ba080b42-dcf8-4dd6-bdf3-203026822bb7 \
# 8g: --flavor 582de800-4e1a-459c-982e-488ba306abde \

nova boot \
  --flavor 582de800-4e1a-459c-982e-488ba306abde \
  --image 374280d9-b508-4729-96f5-ececbab70c7b \
  --key-name some-key-name \
  --nic net-id=fdce48ad-7707-4b53-8fc7-86d1cbf041cc \
  --meta i_was_born=$(date -u +%s) \
  --user-data ./user-data \
  some-server-name

