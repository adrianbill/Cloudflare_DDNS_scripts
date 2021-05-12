#!/bin/bash

# Simple script to run multiple ddns-domain scripts at once

#INPUTS

DOMAINS=("domain1.com" "domain2.net" "domain3.com") #Populate domains in DOMAINS Array
SCRIPT_PATH="/opt/scripts/ddns/" # Location of domain scripts

#Email info, email only sent if IP address is changed
SENDER="email address"
RECIPIENT="email address"
SUBJECT="[DDNS] Status Report: IP CHANGE" #Subject line of email


#MAIN

echo "" > ${SCRIPT_PATH}log-ddns.txt # clear logs

EXIT_CODES=()

# Run wach domain dns updater script and capture exit code
for (( i=0; i<${#DOMAINS[@]}; i++))
do
    ${SCRIPT_PATH}ddns-${DOMAINS[$i]}.sh
    EXIT_CODES[$i]=`echo $?`
    wait
    cat  ${SCRIPT_PATH}log-${DOMAINS[$i]}.txt >>  ${SCRIPT_PATH}log-ddns.txt
done

# send email if IP address changes
if [[ ! "${EXIT_CODES[@]}" =~ "170" ]]; then
    echo "From: $SENDER" > ${SCRIPT_PATH}email-ddns.txt
    echo "To: $RECIPIENT" >> ${SCRIPT_PATH}email-ddns.txt
    echo "Subject: $SUBJECT" >> ${SCRIPT_PATH}email-ddns.txt
    echo "" >> ${SCRIPT_PATH}email-ddns.txt
    echo "Server IP address changed:" >> ${SCRIPT_PATH}email-ddns.txt
    echo "" >> ${SCRIPT_PATH}email-ddns.txt
    cat ${SCRIPT_PATH}log-ddns.txt >> ${SCRIPT_PATH}email-ddns.txt
    /usr/sbin/sendmail -t < ${SCRIPT_PATH}email-ddns.txt
fi
