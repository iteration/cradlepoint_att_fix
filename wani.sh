#!/bin/bash

# WAN1.sh
#
# Accepts target, maximum number of fails, Max iterations to go and max latency to expect
# Uses defaults if no input provided

#Generate Parameters
#target=${1:-www.google.com}
#maxnumberoffails=${2:-3}
#maxiterations=${3:-5}
#maxlatency=${4:-200}
target=www.msn.com
maxnumberoffails=3
maxiterations=5
maxlatency=200

#Set variables and create/overwrite log
logger -p user.warning -t "P_C" "##########################"
logger -t "P_C" "Starting Up"
#logger -t "P_C" $@
#Params: G eth0 OK << defined by the edgerouter.
#Statuses: OK | DOWN
interface=${2:-eth0}
currentStatus=${3:-OK}

logger -t "P_C" "Interface: "$interface
logger -t "P_C" "Status: "$currentStatus

if [ $currentStatus == 'OK' ]
then
	logger -p user.warning -t "P_C" "This is an HEALTH CHECK."
elif [ $currentStatus == 'DOWN' ]
then
	logger -p user.warning -t "P_C" "This is a RECOVER TEST."
else
	logger -p user.warning -t "P_C" "Status was NOT OK or DOWN?"
fi

logger -p user.warning -t "P_C" "##########################"
#Loop until we run out of iterations
i=0
while [ $i -lt $maxiterations ]; do

	#Build Header
	logger -p user.warning -t "P_C" $i $i $i $i $i $i $i $i $i
	logger -p user.warning -t "P_C" "Iteration: " $i

	#Is the Latency ok?
	latency=$(ping -c 2 $target | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	latency=${latency%.*}
	latency=${latency:-0}
	logger -p user.warning -t "P_C" "Latency is $latency. Max latency is $maxlatency"

	if [ $maxlatency -gt $latency ]
	then
		#Is Target Resolvable?
		host -t a $target
		if [ $? -eq 0 ]
		then
			logger -p user.warning -t "P_C" "Can Resolve Domain to IP " $target

			#Is Target Reachable?
			count=$( ping -c 1 $target | grep icmp* | wc -l )
			if [ $count -eq 0 ]
			then
				logger -p user.warning -t "P_C" "Host is NOT Pingable" $target
				let maxnumberoffails=maxnumberoffails-1
			else
				logger -p user.warning -t "P_C" "Host is Pingable" $target

				logger -p user.warning -t "P_C" "CURL Attempt: "$target

				#Is the target reachable on port 80?  << AT&T Failure!!!
				status_code=$(curl -LI $target -interface $interface -s -m 3 -o /dev/null -w '%{http_code}')

				logger -p user.warning -t "P_C" "Status_code: "${status_code:0:3}
				if [[ ${status_code:0:3} -eq 200 ]] ; then
					logger -t "P_C" "Curl Result: SUCCESS"
				else
					logger -p user.warning -t "P_C" "Curl Result: FAILED"
					let maxnumberoffails=maxnumberoffails-1
				fi
			fi
		else
			logger -p user.warning -t "P_C" "Can NOT Resolve Domain to IP " $target
			let maxnumberoffails=maxnumberoffails-1
		fi
	else
		logger -p user.warning -t "P_C" "Latency Too High " $target
		let maxnumberoffails=maxnumberoffails-1
	fi

	logger -p user.warning -t "P_C" "Failures remaining: $maxnumberoffails"

	if [ $maxnumberoffails -eq 0 ]
	then
		logger -p user.warning -t "P_C" "Max Number of Fails Reached"

		#if the currentStatus was OK and it is failed now, try to fix it.
		# Dont try to fix it again it the connection is DOWN.
		# TODO: Create log of the last time this attempted to fix and try to fix again.
		if [ $currentStatus == 'OK' ]
		then
			logger -p user.warning -t "P_C_FIX" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			logger -p user.warning -t "P_C_FIX" "   Attempting to run fix script..."
			logger -p user.warning -t "P_C_FIX" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			./config/scripts/fix_cba850.sh
		else
			logger -p user.warning -t "P_C_FIX" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			logger -p user.warning -t "P_C_FIX" "   DID NOT ATTEMPT TO FIX."
			logger -p user.warning -t "P_C_FIX" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		fi

		logger -p user.warning -t "P_C" "Exiting with Failure"

		exit 1
	fi

	let i=i+1
done

logger -p user.warning -t "P_C" "Competed $maxiterations iterations with $maxnumberoffails failures remaining."
logger -p user.warning -t "P_C" "Exiting with Success."
exit 0