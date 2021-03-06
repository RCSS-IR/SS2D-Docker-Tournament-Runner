#!/usr/bin/env bash
source ./utils.sh

sudo iptables-restore < default-routes.txt

for server in $(ls configs); do
  	source ./configs/$server
	# SERVER_NAME=$(head -n1 configs/$server)
	# SERVER_SUBNET=$(head -n2 configs/$server | tail -n1)
	# SERVER_IP=$(head -n3 configs/$server | tail -n1)
	# SERVER_PORT=$(head -n4 configs/$server | tail -n1)
	# SERVER_START_LEFT_CPU=$(head -n5 configs/$server | tail -n1)
	# SERVER_END_LEFT_CPU=$(head -n6 configs/$server | tail -n1)
		#     SERVER_START_RIGHT_CPU=$(head -n7 configs/$server | tail -n1)
		#     SERVER_END_RIGHT_CPU=$(head -n8 configs/$server | tail -n1)
	echo $SERVER_NAME $SERVER_SUBNET
	RUN "docker network rm ${SERVER_NAME}" -nc
	RUN "docker network create  --subnet=${SERVER_SUBNET} ${SERVER_NAME}"
	
	# General policy
	RUN "sudo iptables -I FORWARD -s ${SERVER_SUBNET} -j DROP"
	RUN "sudo iptables -I INPUT -s ${SERVER_SUBNET} -j DROP"
	RUN "sudo iptables -I OUTPUT -s ${SERVER_SUBNET} -j DROP"

	# Connect to server 
	RUN "sudo iptables -I FORWARD -s ${SERVER_IP} -j ACCEPT"
	RUN "sudo iptables -I INPUT -s ${SERVER_IP} -j ACCEPT"
	RUN "sudo iptables -I OUTPUT -s ${SERVER_IP} -j ACCEPT"

	# Connect to server
	RUN "sudo iptables -I FORWARD -s ${SERVER_SUBNET} -d ${SERVER_IP}  -j ACCEPT"
	RUN "sudo iptables -I INPUT -s ${SERVER_SUBNET} -d ${SERVER_IP}  -j ACCEPT"
	RUN "sudo iptables -I OUTPUT -s ${SERVER_SUBNET} -d ${SERVER_IP}  -j ACCEPT"
done
