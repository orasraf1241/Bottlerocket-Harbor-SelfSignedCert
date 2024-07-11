#!/bin/bash

# Prompt user for domain name
read -p "Enter your desired domain name: " domain_name

# Generate CA key
openssl genrsa -out ca.key 4096

# Generate CA certificate (replace "example" with your actual organization name)
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=your_organization_name/OU=Personal/CN=$domain_name" \
  -key ca.key \
  -out ca.crt

# Generate server key
openssl genrsa -out "$domain_name.key" 4096

# Generate server certificate signing request
openssl req -sha512 -new \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=your_organization_name/OU=Personal/CN=$domain_name" \
  -key "$domain_name.key" \
  -out "$domain_name.csr"

# Create extension file with user-provided domain name
cat << EOF > v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$domain_name
DNS.2=$domain_name
DNS.3=$domain_name
EOF

# Generate server certificate with SANs
openssl x509 -req -sha512 -days 3650 \
  -extfile v3.ext \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in "$domain_name.csr" \
  -out "$domain_name.crt"


openssl x509 -inform PEM -in "$domain_name.crt" -out "$domain_name.cert"


mkdir /etc/docker/certs.d
mkdir /etc/docker/certs.d/$domain_name/
cp "$domain_name.cert" /etc/docker/certs.d/$domain_name/
cp "$domain_name.key" /etc/docker/certs.d/$domain_name/
cp ca.crt /etc/docker/certs.d/$domain_name/

systemctl restart docker

ca.crt  ca.key  ca.srl  harbor-test.com.cert  harbor-test.com.crt  harbor-test.com.csr  harbor-test.com.key  v3.ext
/home/ec2-user/harbor/cert
ca.crt  ca.key  ca.srl  harbor-test.com.cert  harbor-test.com.crt  harbor-test.com.csr  harbor-test.com.key  v3.ext
