#!/bin/sh
# initialize nfs-server
echo 'installing nfs-common'
sudo -u root apt install nfs-common -y -qq
# echo 'Creating .env file'
# touch .env && echo 'CURR_DIR='$PWD >> .env

echo 'Checking docker installation...'
if [ "$(which docker)" ]; then
    echo "Docker found!"
    if [ "$(which docker-compose)" ]; then
        echo "docker-compose found!"
    else
        echo "please install docker-compose"
        exit 0
    fi
else
    echo "please install docker"
    exit 0
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

sudo -u root chmod -R 0444  $CURR_DIR/mnt/local-nfs

echo 'all set ! firing up nfs server !'
docker-compose up -d