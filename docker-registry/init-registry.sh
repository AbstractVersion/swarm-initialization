#!/bin/sh
# initialize nfs-server
echo 'installing depentencies...'
sudo -u root apt-get install git -y -qq
sudo -u root apt-get install curl -y -qq

echo 'Checking docker installation...'
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

IP=127.0.0.1
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
sudo cp ../depentencies/certificate/private-registry-cert.crt /etc/docker/certs.d/private.registry.io/

# And then create a new directory '/usr/share/ca-certificate/extra' and copy the Root CA certificate into it.
sudo mkdir -p /usr/share/ca-certificates/extra/
sudo cp ../depentencies/certificate/private-registry-cert.crt /usr/share/ca-certificates/extra/

# Update certificates & restart docker
sudo dpkg-reconfigure ca-certificates
sudo systemctl restart docker

echo 'all set ! firing up docker-registry with under dns private.registry.io, make sure all your hosts file point to this dns !'
docker-compose up -d