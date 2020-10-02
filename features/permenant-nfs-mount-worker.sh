#!/bin/sh
# Generally, you will want to mount the remote NFS directory automatically when the system boots.
# The /etc/fstab file contains a list of entries that define where how and what filesystem will be mounted on system startup.
# To automatically mount an NFS share when your Linux system starts up add a line to the /etc/fstab file. The line must include the hostname or the IP address of the NFS server, the exported directory, and the mount point on the local machine.
# Use the following procedure to automatically mount an NFS share on Linux systems:


# Managers
# Set up a mount point for the remote NFS share:
# su -

# mkdir -p /mnt/local-nfs/logstash-conf
# echo 'swarmNfs.server.io:/logstash-conf /mnt/local-nfs/logstash-conf  nfs      defaults    0       0' >> /etc/fstab

# Workers
su -

mkdir -p /mnt/local-nfs/filebeat/
echo 'swarmNfs.server.io:/filebeat-conf /mnt/local-nfs/filebeat/  nfs      defaults    0       0' >> /etc/fstab