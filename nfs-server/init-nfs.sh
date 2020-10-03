#!/bin/sh
# initialize nfs-server
echo 'installing nfs-common...'
sudo -u root apt install nfs-common -y -qq
echo 'installing git...'
sudo -u root apt-get install git -y 

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
        docker image rm hello-world
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

echo "Checking .env file"
if [ "$(cat .env)" ]; then
        CURR_DIR=$(grep CURR_DIR .env | cut -d '=' -f2)
else
    touch .env && echo 'CURR_DIR='$PWD >> .env
    CURR_DIR=$(grep CURR_DIR .env | cut -d '=' -f2)
fi


### Check if a directory does not exist ###
if [ ! -d "$CURR_DIR/mnt/local-nfs" ] 
then
    echo "Directory $CURR_DIR/mnt/local-nfs DOES NOT exists." 
    exit 9999 # die with error code 9999
fi

# sudo -u root chmod -R 0444  $CURR_DIR/mnt/local-nfs
sudo -u root chmod -R go-w $CURR_DIR/mnt/local-nfs/logstash-conf/
sudo -u root chmod -R go-w $CURR_DIR/mnt/local-nfs/filebeat-conf/filebeat.docker.yml 

echo 'all set ! firing up nfs server !'
docker-compose up -d