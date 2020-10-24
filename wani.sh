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
logger -t "PING_CURL" "Starting Up"
#logger -t "PING_CURL" $@
#Params: G eth0 OK << defined by the edgerouter.
interface=${2:"eth0"}
exitStatus=${3:"OK"}

#Loop until we run out of iterations
i=0
while [ $i -lt $maxiterations ]; do

	#Build Header
	logger -p user.warning -t "PING_CURL" "#####################"
	logger -p user.warning -t "PING_CURL" "Iteration: " $i

	#Is the Latency ok?
	latency=$(ping -c 2 $target | tail -1| awk '{print $4}' | cut -d '/' -f 2)
	latency=${latency%.*}
	latency=${latency:-0}
	logger -p user.warning -t "PING_CURL" "Latency is $latency. Max latency is $maxlatency"

	if [ $maxlatency -gt $latency ]
	then
		#Is Target Resolvable?
		host -t a $target
		if [ $? -eq 0 ]
		then
			logger -p user.warning -t "PING_CURL" "Can Resolve Domain to IP " $target

			#Is Target Reachable?
			count=$( ping -c 1 $target | grep icmp* | wc -l )
			if [ $count -eq 0 ]
			then
				logger -p user.warning -t "PING_CURL" "Host is NOT Pingable" $target
				let maxnumberoffails=maxnumberoffails-1
			else
				logger -p user.warning -t "PING_CURL" "Host is Pingable" $target

				logger -p user.warning -t "PING_CURL" "CURL Attempt: " $target
				#Is the target reachable on port 80?  << AT&T Failure!!!
				http_code=$(curl -LI $target -interface $interface -o /dev/null -w '%{http_code}\n' -s -m 3)
				if [ ${http_code} -eq 200 ]; then
					logger -t "PING_CURL" "Curl Result: SUCCESS"
				else
					logger  -p user.emerg -t "PING_CURL" "Curl Result: FAILED"
					let maxnumberoffails=maxnumberoffails-1
				fi
			fi
		else
			logger -p user.emerg -t "PING_CURL" "Can NOT Resolve Domain to IP " $target
			let maxnumberoffails=maxnumberoffails-1
		fi
	else
		logger -p user.emerg -t "PING_CURL" "Latency Too High " $target
		let maxnumberoffails=maxnumberoffails-1
	fi

	logger -p user.warning -t "PING_CURL" "Failures remaining: $maxnumberoffails"

	if [ $maxnumberoffails -eq 0 ]
	then
		logger -p user.emerg -t "PING_CURL" "Max Number of Fails Reached"
		logger -p user.emerg -t "PING_CURL_FIX" "Attempting to run fix script..."
		./config/scripts/fix_cba850.sh
		logger -p user.emerg -t "PING_CURL" "Exiting with Failure"

		exit 1
	fi

	let i=i+1
done

logger -p user.warning -t "PING_CURL" "Competed $maxiterations iterations with $maxnumberoffails failures remaining."
logger -p user.warning -t "PING_CURL" "Exiting with Success."
exit 0