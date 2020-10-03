#!/bin/sh
# Swarm Worker Initialization
echo 'Checking docker installation...'
sudo -u root apt-get install curl -y -qq 

if [ "$(which docker)" ]; then
    echo "Docker found!"
else
    read -p "Do you want to install docker ? (y/n) " RESP
    if [ "$RESP" = "y" ]; then
        echo "Installing Docker for you."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        sudo -u root usermod -aG docker $USER
        newgrp docker 
        exec su -l $USER
        docker run hello-world
        docker image rm hello-worled
    else
        echo "Exiting installation."
        exit 0
    fi
fi
if [ "$(which docker-compose)" ]; then
    echo "docker-compose found!"
else
    read -p "Do you want to install docker compose ? (y/n) " RESP
    if [ "$RESP" = "y" ]; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
    else
        echo "Exiting installation."
        exit 0
    fi
fi

echo "---------------------------------- Swarm Leader Initialization -------------------------------------------------"

# Automatically get the ip address from eth0 interface.
# ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

# Get the ip address of the network in which the rest of the Docker-Engines are visible.
read -p "Enter the advertise address of the Swarm Leader (The ip of network interface that swarm will use to advertise itself): \t"  addv_addr

docker swarm init --advertise-addr $addv_addr


echo "----------------- Inserting private image repository's certificate on trasted crts --------------------------- \n"
echo "make sure you have the correct crt file placed in : docker-registry/nginx/ssl/private-registry-cert.crt  \n"   
echo "make sure to select the extra/private-registry-cert.crt from the trusted list, this will be the certificate of your repository which poits to the private key that serves TLS"

 # PATH TO YOUR HOSTS FILE
ETC_HOSTS=/etc/hosts
read -p "Enter registry IP address: \t"  registry_ip

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

read -p "Do you want trust the registry certificate ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    # Now create a new directory for docker certificate and copy the Root CA certificate into it.
    sudo mkdir -p /etc/docker/certs.d/private.registry.io/
    sudo cp depentencies/certificate/private-registry-cert.crt /etc/docker/certs.d/private.registry.io/

    # And then create a new directory '/usr/share/ca-certificate/extra' and copy the Root CA certificate into it.
    sudo mkdir -p /usr/share/ca-certificates/extra/
    sudo cp depentencies/certificate/private-registry-cert.crt /usr/share/ca-certificates/extra/

    # Update certificates & restart docker
    sudo dpkg-reconfigure ca-certificates
    sudo systemctl restart docker
else
    echo "Ok then proceding."
fi


echo "testing repository..."

read -p "Please provide the repository user the default credentials are {abstract:admin}:   " repo_user



docker image pull alpine:latest
docker image tag alpine:latest private.registry.io/test-alpine:latest
docker login https://private.registry.io/v2/_catalog


echo "------------------------------------ Configuring NFS share volume ------------------------------------"

sudo -u root apt install nfs-common -y -qq

read -p "Please provide NFS server ip address :     " nfs_ip

IP=$nfs_ip

# Hostname to add/remove.
HOSTNAME_NFS='swarmNfs.server.io'
HOSTS_LINE="$IP\t$HOSTNAME_NFS"
if [ -n "$(grep $HOSTNAME_NFS /etc/hosts)" ]
    then
        echo "$HOSTNAME_NFS already exists : $(grep $HOSTNAME_NFS $ETC_HOSTS)"
    else
        echo "Adding $HOSTNAME_NFS to your $ETC_HOSTS";
        sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

        if [ -n "$(grep $HOSTNAME_NFS /etc/hosts)" ]
            then
                echo "$HOSTNAME_NFS was added succesfully \n $(grep $HOSTNAME_NFS /etc/hosts)";
            else
                echo "Failed to Add $HOSTNAME_NFS, Try again!";
        fi
fi



read -p "Do you want install the thrid-party driver for the volume sharing ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    # Install theese external tool for volume share among managers
    # Install Netshare Docker Volume Driver
    # Install Netshare which will provide the NFS Docker Volume Driver:
    wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.36/docker-volume-netshare_0.36_amd64.deb
    sudo -u root dpkg -i docker-volume-netshare_0.36_amd64.deb
    sudo -u root service docker-volume-netshare start
    sudo systemctl enable docker-volume-netshare

    echo 'testing nfs docker volume driver....'
    docker volume create --driver nfs --name test-nfs-volume -o share=$HOSTNAME_NFS:/
    docker volume inspect test-nfs-volume
    docker volume rm test-nfs-volume
else
    echo "Ok then proceding."
fi

# docker run --rm -it  -v test-nfs-volume:/app/test-data private.registry.io/test-nfs:latest

read -p "Do you want to mount the logstash-configuration directory from the nfs server ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    sudo -u root chmod +x features/permenant-nfs-mount-manager.sh
    sudo -u root features/permenant-nfs-mount-manager.sh
    sudo -u root mount /mnt/local-nfs/logstash-conf
else
    echo "Ok then proceding."
fi

# On Workers
# sudo -u root mount -t nfs $HOSTNAME:/filebeat-conf /nfs/micor-env/config/filebeat
# sudo -u root mount 192.168.2.4:/filebeat-conf /nfs/micor-env/config/filebeat

