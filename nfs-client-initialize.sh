#   Configuration of Clients
sudo -u root apt install nfs-common -y

# Install theese external tool for volume share among managers
# Install Netshare Docker Volume Driver
# Install Netshare which will provide the NFS Docker Volume Driver:
wget https://github.com/ContainX/docker-volume-netshare/releases/download/v0.36/docker-volume-netshare_0.36_amd64.deb
sudo -u root dpkg -i docker-volume-netshare_0.36_amd64.deb
sudo -u root service docker-volume-netshare start

sudo mkdir -p /nfs/micor-env/config/{filebeat,logstash}

# On Workers
sudo -u root mount 192.168.2.4:/filebeat-conf /nfs/micor-env/config/filebeat
#On managers
sudo -u root mount 192.168.2.4:/logstash-conf /nfs/micor-env/config/logstash


# docker create volume
# docker volume create --driver nfs --name foobar2 -o share=192.168.2.4:/foobar2
# docker volume inspect foobar2
