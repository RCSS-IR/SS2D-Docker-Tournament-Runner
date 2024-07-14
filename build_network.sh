#!/usr/bin/env bash
source ./utils.sh

sudo iptables-restore < default-routes.txt

for server in $(ls configs); do
    # Ignore .py files
    if [[ "$server" == *.py ]]; then
        continue
    fi

    source ./configs/$server

    # Ignore files with IGNORE=true
    if [[ "$IGNORE" == "true" ]]; then
        continue
    fi

    echo $SERVER_NAME $SERVER_SUBNET
    RUN "docker network rm ${SERVER_NAME}" -nc
    RUN "docker network create --subnet=${SERVER_SUBNET} ${SERVER_NAME}"

    # General policy
    RUN "sudo iptables -I FORWARD -s ${SERVER_SUBNET} -j DROP"
    RUN "sudo iptables -I INPUT -s ${SERVER_SUBNET} -j DROP"
    RUN "sudo iptables -I OUTPUT -s ${SERVER_SUBNET} -j DROP"

    # Connect to server
    RUN "sudo iptables -I FORWARD -s ${SERVER_IP} -j ACCEPT"
    RUN "sudo iptables -I INPUT -s ${SERVER_IP} -j ACCEPT"
    RUN "sudo iptables -I OUTPUT -s ${SERVER_IP} -j ACCEPT"

    # Connect to server
    RUN "sudo iptables -I FORWARD -s ${SERVER_SUBNET} -d ${SERVER_IP} -j ACCEPT"
    RUN "sudo iptables -I INPUT -s ${SERVER_SUBNET} -d ${SERVER_IP} -j ACCEPT"
    RUN "sudo iptables -I OUTPUT -s ${SERVER_SUBNET} -d ${SERVER_IP} -j ACCEPT"
done
