#!/bin/sh
# Swarm Worker Initialization
echo "---------------------------------- Docker Installation -------------------------------------------------"

read -p "Do you want to install docker ? (y/n) " RESP
    if [ "$RESP" = "y" ]; then
        sudo apt-get remove docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        # sudo groupadd docker
        sudo usermod -aG docker $USER
        newgrp docker 

        #testing docker command
        echo "testing docker command"
        docker --versions
        docker run hello-world
    else
        echo "proceeding with the installation."
    fi

read -p "Do you want to install docker compose ? (y/n) " RESP
    if [ "$RESP" = "y" ]; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
    else
        echo "proceeding with the installation."
    fi


echo "---------------------------------- Swarm Worker Initialization -------------------------------------------------"


echo "please run the command [ docker swarm join-token worker ] on your leader or a manager to retrieve the token the ip & the port\n"

read -p "Please provide the swarn token & press enter:\n" swarm_token
read -p "Please provide the swarn leader ip & press enter:\n" swarm_leader_ip
read -p "Please provide the swarn api port & press enter:\n" swarm_leader_port

echo '\n'

echo "Registering node as worker on the swarm clustr, the node will be marked as host : "$HOSTNAME
docker swarm join \
    --token $swarm_token \
    $swarm_leader_ip:$swarm_leader_port

echo "----------------- Inserting private image repository's certificate on trasted crts --------------------------- \n"
echo "make sure you have the correct crt file placed in : docker-registry/nginx/ssl/private-registry-cert.crt  \n"   
echo "make sure to select the extra/private-registry-cert.crt from the trusted list, this will be the certificate of your repository which poits to the private key that serves TLS"

 # PATH TO YOUR HOSTS FILE
ETC_HOSTS=/etc/hosts
read -p "Enter registry IP address: \t"  registry_ip

    # sudo su
    # echo $registry_ip'    private.registry.io' >> /etc/hosts
    #  echo '192.168.2.8   private.registry.io' >> /etc/hosts
    # exit
    # DEFAULT IP FOR HOSTNAME
IP=$registry_ip

# Hostname to add/remove.
HOSTNAME='private.registry.io interface.registry.io'
HOSTS_LINE="$IP\t$HOSTNAME"
if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
    then
        echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
    else
        echo "Adding $HOSTNAME to your $ETC_HOSTS";
        sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

        if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
            then
                echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
            else
                echo "Failed to Add $HOSTNAME, Try again!";
        fi
fi


# Now create a new directory for docker certificate and copy the Root CA certificate into it.
sudo mkdir -p /etc/docker/certs.d/private.registry.io/
sudo cp ../../depentencies/certificate/private-registry-cert.crt /etc/docker/certs.d/private.registry.io/

# And then create a new directory '/usr/share/ca-certificate/extra' and copy the Root CA certificate into it.
sudo mkdir -p /usr/share/ca-certificates/extra/
sudo cp ../../depentencies/certificate/private-registry-cert.crt /usr/share/ca-certificates/extra/

# Update certificates & restart docker
sudo dpkg-reconfigure ca-certificates
sudo systemctl restart docker


echo "testing repository..."

read -p "Please provide the repository user the default credentials are {abstract:admin}:   " repo_user

http -a $repo_user https://private.registry.io/v2/_catalog

docker image pull alpine:latest
docker image tag alpine:latest private.registry.io/test-alpine:latest
docker login https://private.registry.io/v2/_catalog


echo "------------------------------------ Configuring NFS share volume ------------------------------------"

sudo -u root apt install nfs-common -y

read -p "Please provide NFS server ip address :     " nfs_ip

# Install theese external tool for volume share among managers
# Install Netshare Docker Volume Driver
# Install Netshare which will provide the NFS Docker Volume Driver:
wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.36/docker-volume-netshare_0.36_amd64.deb
sudo -u root dpkg -i docker-volume-netshare_0.36_amd64.deb
sudo -u root service docker-volume-netshare start

echo 'testing nfs docker volume driver....'
docker volume create --driver nfs --name test-nfs-volume -o share=$nfs_ip:/hi
docker volume inspect test-nfs-volume
docker volume rm test-nfs-volume
# docker run --rm -it  -v test-nfs-volume:/app/test-data private.registry.io/test-nfs:latest


sudo mkdir -p /nfs/micor-env/config/{filebeat,logstash}
# On Workers
sudo -u root mount $nfs_ip:/filebeat-conf /nfs/micor-env/config/filebeat



