#!/bin/sh
# This is a comment!

echo ----------------------------------------------- Active Hosts of the Swarm Cluster -------------------------------------------


echo ---- Arctive Swarm Nodes----

docker node ls

echo "\n"

echo ----------------------------------------------- Managers of the Swarm Cluster -----------------------------------------------

docker node ls --filter role=manager

echo "\n"

echo ----------------------------------------------- Workers of the Swarm Cluster ------------------------------------------------
docker node ls --filter role=worker




# Docker Swarm Overlay Networks
echo Current Active networks :

docker network ls

read -p "Create Shared volumes ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    echo Creating Swarm Networks

        docker network create -d overlay micro-nework-frontend
        docker network create -d overlay micro-nework-backend
        docker network create -d overlay elastic-stack-network

        echo Current Active networks :

        docker network ls
else
    echo "Ok then proceeding with the initialization..."
fi






#------------------------------------ Initializeing NFS ---------------------------------------------
#https://vitux.com/install-nfs-server-and-client-on-ubuntu/


read -p "Do you want to install NFS server here ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    echo 'Installing NFS Server for File sharing, you will need a sudoer'
    #Update apt & install nfs kernel
    sudo apt-get update
    sudo apt install nfs-kernel-server

    # Create shared directory, you can change this value to point to the directory of your preferences, just bear in mind that this directory will
    # be shared accross all manager nodes.
    sudo mkdir -p /mnt/sharedfolder

    # Assigne the filesystem permissions so as the directory to be accessible by the NFS.
    sudo chown nobody:nogroup /mnt/sharedfolder
    sudo chmod 777 /mnt/sharedfolder
    
    sudo cat /etc/exports

    
    echo 'Adding clients to NFS, you will need root for that'
    sudo -u root rm -rf ./exports
    touch ./exports
    for NODE in $(docker node ls --filter role=manager --format '{{.Hostname}}')
    do 
        echo  "Adding as client :\t${NODE} - $(docker node inspect --format '{{.Status.Addr}}' "${NODE}")"
        q=$(docker node inspect --format '{{.Status.Addr}}' ${NODE})
        echo  "/mnt/sharedfolder $q(rw,sync,no_subtree_check)" >> ./exports
        # echo '"/mnt/sharedfolder '$q'(rw,sync,no_subtree_check)" >> /etc/exports'
        
        # temp = "$(docker node inspect --format '{{.Status.Addr}}' "${NODE}"
        # echo $temp
        # sudo echo  "/mnt/sharedfolder $temp(rw,sync,no_subtree_check)"$'\r' >> /etc/exports

        echo "Allowing client through debian ip-tables : \t" $(docker node inspect --format "{{.Status.Addr}}" ${NODE})
        sudo -u root iptables -A INPUT -s $q -j ACCEPT
        echo '\n'
    done
    sudo -u root cp -fr ./exports /etc/exports
    # After making all the above configurations in the host system, 
    # now is the time to export the shared directory through the following command as sudo:
    sudo -u root exportfs -a

    # Finally, in order to make all the configurations take effect, 
    # restart the NFS Kernel server as follows:

    sudo -u root systemctl restart nfs-kernel-server
else
    echo "Ok then proceeding with the initialization..."
fi


read -p "Create Shared volumes (this will register as client this machine to the NFS server) ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
    sudo -u root apt-get update && sudo -u root apt-get install nfs-common
    sudo -u root mkdir -p /mnt/sharedfolder

    # sudo -u root mkdir -p /mnt/sharedfolder/volumes/data/elsasticsearch
    # sudo -u root mkdir -p /mnt/sharedfolder/volumes/data/mariadb  

    echo 'please provide the NFS server ip :'
    read input
    sudo -u root mount -t nfs $input:/mnt/sharedfolder /mnt/sharedfolder

    docker volume create --driver local \
      --opt type=none \
      --opt device=/mnt/sharedfolder/volumes/data/elsasticsearch \
      elsasticsearch-volume
else
    echo "Ok then proceeding with the initialization..."
fi

read -p "Do you want to create a registry service to push your images localy ? (y/n) " RESP
if [ "$RESP" = "y" ]; then
#    1.Start the registry as a service on your swarm:
    # docker service create --name registry --publish published=5000,target=5000 registry:2
    docker run -d \
        -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
        -p 5000:5000 \
        --name registry \
        registry:2
    watch docker service ls
# 2.Check its status with docker service ls:
else
    echo "Ok then proceeding with the initialization..."
fi

## REGISTRY
# certificate generation
#https://www.akadia.com/services/ssh_test_certificate.html
mkdir certs && cd certs

docker run -t -d -v /opt/registry-v1:/tmp/registry-dev --name docker-registry-v1 registry:0.9.1

#Registry user, password generation
htpasswd -c htpasswd userXXX

#Step 1: Generate a Private Key
openssl genrsa -des3 -out docker-registry.key 1024

# Step 2: Generate a CSR (Certificate Signing Request)
openssl req -new -key docker-registry.key -out docker-registry.csr

#Step 3: Remove Passphrase from Key
cp docker-registry.key docker-registry.key.org
openssl rsa -in docker-registry.key.org -out docker-registry.key

# Step 4: Generating a Self-Signed Certificate

openssl x509 -req -days 365 -in docker-registry.csr -signkey docker-registry.key -out docker-registry.crt


docker run -t -d -p 443:443 -e REGISTRY_HOST="docker-registry-v1" \
-e REGISTRY_PORT="5000" -e SERVER_NAME="register.example.com" \
--link docker-registry-v1:docker-registry-v1 \
-v /home/abstract/htpasswd:/etc/nginx/.htpasswd:ro \
-v /home/abstract/certs:/etc/nginx/ssl:ro \
jmaciasportela/docker-registry-proxy-v1