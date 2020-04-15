#!/bin/sh
# Swarm Worker Initialization

echo "please run the command [ docker swarm join-token worker ] on your leader or a manager to retrieve the token the ip & the port"

read -p "Please provide the swarn token & press enter" swarm_token
read -p "Please provide the swarn leader ip & press enter" swarm_leader_ip
read -p "Please provide the swarn api port & press enter" swarm_leader_port

echo "Registering node as worker on the swarm clustr, the node will be marked as host : "$HOSTNAME
docker swarm join \
    --token $swarm_token \
    $swarm_leader_ip:$swarm_leader_port