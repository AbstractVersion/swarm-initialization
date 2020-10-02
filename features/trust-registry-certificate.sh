# Now create a new directory for docker certificate and copy the Root CA certificate into it.
sudo mkdir -p /etc/docker/certs.d/private.registry.io/
sudo cp ../depentencies/certificate/private-registry-cert.crt /etc/docker/certs.d/private.registry.io/

# And then create a new directory '/usr/share/ca-certificate/extra' and copy the Root CA certificate into it.
sudo mkdir -p /usr/share/ca-certificates/extra/
sudo cp ../depentencies/certificate/private-registry-cert.crt /usr/share/ca-certificates/extra/

# Update certificates & restart docker
sudo dpkg-reconfigure ca-certificates
sudo systemctl restart docker
