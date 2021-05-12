#!/bin/bash

# Script to auto-update the CloudFlare DNS entry if the computer's public IP address changes.

#Required Data, use get-info script if missing zone id or record id
DOMAIN_NAME="[replace with domain name]" # use only domain name and top level dome e.g. "google.com" 
AUTH_EMAIL="[replace with login email]"
AUTH_KEY="[replace with global auth key]"
ZONE_ID="[replace with Zone id]"
RECORD_ID="[replace with Record id]"

# Location to save cache and log
CACHE_PATH="/opt/scripts/ddns/cache-$DOMAIN_NAME.txt"
LOG_PATH="/opt/scripts/ddns/log-$DOMAIN_NAME.txt"

# The current IP address and path to the IP cache file
IP_ADDRESS=`dig +short myip.opendns.com @resolver1.opendns.com`

# Fetch last value of IP address sent to server or create cache file
if [ ! -f $CACHE_PATH ]
then 
    touch $CACHE_PATH
fi

CURRENT=$(<$CACHE_PATH)

#log ip address data to log
echo "$(date): $DOMAIN_NAME - Check WAN:$IP_ADDRESS ARec:$CURRENT" > $LOG_PATH

# If IP address hasn't changed, exit, otherwise save the new IP
if [ "$IP_ADDRESS" == "$CURRENT" ]
then 
    exit 0
fi

#store IP address to cache
echo $IP_ADDRESS > $CACHE_PATH

# Update CloudFlare
echo "$(date): $DOMAIN_NAME - Updating cloudflare" >> $LOG_PATH
echo -n "$(date): " >> $LOG_PATH
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
        -H "X-Auth-Email: $AUTH_EMAIL" \
        -H "X-Auth-Key: $AUTH_KEY" \
        -H "Content-Type: application/json" \
        --data '{"type": "A", "name": "'$DOMAIN_NAME'", "content": "'$IP_ADDRESS'"}' \
    >> $LOG_PATH
echo "" >> $LOG_PATH
exit 170 #exit code used to signal to another script that IP address has changed
