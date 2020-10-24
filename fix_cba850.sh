#!/bin/bash
username="admin"
password="<your password here>"

logger -p user.emerg -t "CB850" "######################################################################"
logger -p user.emerg -t "CB850"  "Attempting to fix the CBA850 by disabling and reenabling SIM1."
logger -p user.emerg -t "CB850"  "######################################################################"

logger -p user.emerg -t "CB850" "Is SIM1 currently disabled?\n"
curl -u $username:$password http://192.168.0.1/api/status/wan/devices/mdm-5a9dbcf7/config/disabled --location
sleep 5  # Waits 5 seconds

logger -p user.emerg -t "CB850" "Disable SIM1 and wait 10 seconds..."
curl -u $username:$password -X PUT http://192.168.0.1/api/config/wan/rules2/0/disabled?data=true --location
sleep 10  # Waits 5 seconds

logger -p user.emerg -t "CB850" "Reenable SIM1 and allow for recovery..."
curl -u $username:$password -X PUT http://192.168.0.1/api/config/wan/rules2/0/disabled?data=false --location

logger -p user.emerg -t "CB850"  "...Operations completed. Modem may take time to transistion."


