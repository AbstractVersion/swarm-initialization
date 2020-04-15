#COnfiguration of server
# In order to mount NFS drives we need to install the following:
sudo -u root apt install nfs-common -y
# https://sysadmins.co.za/docker-swarm-persistent-storage-with-nfs/
# Create NFS Server:
# We have 2 options, we can either install a NFS Server (you can follow this post to setup a NFS Server )  
# or we can setup a NFS Server using Docker (explained below):

# Prepare the NFS Home Directory:
sudo -u root mkdir /nfsdata

## Change the ip to the ip of the NFS server host
docker run --rm -itd --name nfs \
  --privileged \
  -v /nfsdata:/nfs.1 \
  -e SHARED_DIRECTORY=/nfs.1 \
  -p 192.168.2.4:2049:2049 \
  itsthenetwork/nfs-server-alpine:latest


# # Run a container with the volume namespace:
# docker run -i -t -v foobar2:/mount alpine /bin/sh

# ## ON SERVER
# mkdir /nginx_web

# version: "3.7"
# services:
#   web:
#     image: nginx
#     volumes:
#       - nginx.vol:/usr/share/nginx/html
#     ports:
#       - 80:80
#     networks:
#       - web

# networks:
#   web:
#     driver: overlay
#     name: web

# volumes:
#   nginx.vol:
#     driver: nfs
#     driver_opts:
#       share: 10.0.2.15:/nginx_web

#       docker stack deploy -c docker-compose.yml app