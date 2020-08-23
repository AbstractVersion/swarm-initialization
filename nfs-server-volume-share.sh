#!/bin/sh
# Docker volume share accross swarm cluster with NFS.
# This script aims to install the NFS server and configure the shared directory in which swarm-volumes will be stored, so as to be distributed later.
echo "---------------------------------- NFS server installation & Configuration -------------------------------------------------"


# Configuration of server
# In order to mount NFS drives we need to install the following:
sudo -u root apt install nfs-common -y
sudo -u root apt install  nfs-utils -y
# https://sysadmins.co.za/docker-swarm-persistent-storage-with-nfs/
# Create NFS Server:
# We have 2 options, we can either install a NFS Server (you can follow this post to setup a NFS Server )  
# or we can setup a NFS Server using Docker (explained below):

# Prepare the NFS Home Directory:
sudo -u root mkdir /nfs-swarm-share

read -p "Please provide the ip address of the host machine that the NFS server will be isntalled : \t"  nfs_ip

    # sudo su
    # echo $registry_ip'    private.registry.io' >> /etc/hosts
    #  echo '192.168.2.8   private.registry.io' >> /etc/hosts
    # exit
    # DEFAULT IP FOR HOSTNAME

## Change the ip to the ip of the NFS server host
docker run -itd --name nfs-swarm \
  --restart unless-stopped \
  --privileged \
  --network=host \
  -v /nfs-swarm-share/:/nfs.1 \
  -e SHARED_DIRECTORY=/nfs.1 \
  -p $nfs_ip:2049:2049 \
  itsthenetwork/nfs-server-alpine:latest


