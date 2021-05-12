#!/bin/bash  

# This a bash script which will retrieve the necesary information from cloudflare for use with the
# accompanying DDNS script.

##########################
#Help                    #
##########################
Help()
{
	echo
	echo "Usage: ./get-id-info.sh [options] Login_Email  API_KEY"
	echo
	echo "This script retrieves the Cloudflare Zone ID and Record ID using Cloudflare's API for use with the accompanying DDNS script."
	echo 
	echo "options:"
	echo "-h    Print this Help"
	echo
}


##########################
#Main Script             #
##########################

# Get Options
while getopts ":h" option; do
	case $option in
		h ) # display Help function
			Help
			exit;;
	esac
done

#Check Arguments
if [ "$#" -ne 2 ]
then
    echo
	echo "Illegal number of parameters"
	echo
	echo "Usage: ./get-id-info.sh [options] Login_Email  API_KEY"
	echo
	exit
fi

#Assign Arguments
AUTH_EMAIL=$1
AUTH_KEY=$2

#Initialize arrays
DOMAINS=()
ZONE_IDS=()
RECORD_IDS=()

# temp query file
temp_query_file="query_$AUTH_EMAIL.json"

#Request Data
curl -s \
	-X GET "https://api.cloudflare.com/client/v4/zones" \
	-H "X-Auth-Email: $AUTH_EMAIL" \
	-H "X-Auth-Key: $AUTH_KEY" \
	-H "Content-Type: application/json" > temp_query_file

#Check for success
SUCCESS=`cat temp_query_file | jq -r ".success"`

if [ "$SUCCESS" = "false" ]
then	
	ERROR_CODE=`cat temp_query_file | jq -r ".errors[].code"`
	ERROR_MES=`cat temp_query_file | jq -r ".errors[].message"`
	echo 
	echo "Request unsuccessful"
	echo "Error Code: $ERROR_CODE"
	echo "Error Message: $ERROR_MES"
	echo
	rm temp_query_file
	exit
fi

#Retrieves number of domains
NUM_DOMAINS=`cat temp_query_file | jq -r ".result_info.total_count"`

#Retrieves domain, zone id and record id using cloudflare api and parsing json file
for (( i=0; i<$NUM_DOMAINS; i++))
do
	DOMAINS[$i]=`cat temp_query_file | jq -r ".result[$i].name"`

	ZONE_IDS[$i]=`cat temp_query_file| jq -r ".result[$i].id"`

	RECORD_IDS[$i]=`curl -s \
					-X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_IDS[$i]}/dns_records" \
					-H "X-Auth-Email: $AUTH_EMAIL" \
					-H "X-Auth-Key: $AUTH_KEY" \
					-H "Content-Type: application/json" \
                | jq -r ".result[0].id"`
done

#remove temp file
rm temp_query_file

#prints the results
for (( j=0; j<$NUM_DOMAINS; j++ ))
do
	echo "---------------------------------------------------"
	echo "Domain: ${DOMAINS[$j]}"
	echo "Zone ID: ${ZONE_IDS[$j]}"
	echo "Record ID: ${RECORD_IDS[$j]}"
done
echo "---------------------------------------------------"
