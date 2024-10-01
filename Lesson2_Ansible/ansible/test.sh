#!/bin/bash

# Set directory for certificates
CERT_DIR="/tmp/certs"
mkdir -p ${CERT_DIR}

# Variables
DAYS=365
ROOT_CA_KEY="${CERT_DIR}/rootCA.key"
ROOT_CA_CRT="${CERT_DIR}/rootCA.crt"
SERVER_KEY="${CERT_DIR}/server.key"
SERVER_CSR="${CERT_DIR}/server.csr"
SERVER_CRT="${CERT_DIR}/server.crt"
CLIENT_KEY="${CERT_DIR}/client.key"
CLIENT_CSR="${CERT_DIR}/client.csr"
CLIENT_CRT="${CERT_DIR}/client.crt"
CLIENT_P12="${CERT_DIR}/client.p12"

# Generate Root CA
openssl genrsa -out ${ROOT_CA_KEY} 4096
openssl req -x509 -new -nodes -key ${ROOT_CA_KEY} -sha256 -days ${DAYS} -out ${ROOT_CA_CRT} -subj "/C=US/ST=State/L=City/O=MyOrg/OU=OrgUnit/CN=RootCA"

# Generate Server Certificate
openssl genrsa -out ${SERVER_KEY} 4096
openssl req -new -key ${SERVER_KEY} -out ${SERVER_CSR} -subj "/C=US/ST=State/L=City/O=MyOrg/OU=OrgUnit/CN=localhost"
openssl x509 -req -in ${SERVER_CSR} -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${SERVER_CRT} -days ${DAYS} -sha256

# Generate Client Certificate
openssl genrsa -out ${CLIENT_KEY} 4096
openssl req -new -key ${CLIENT_KEY} -out ${CLIENT_CSR} -subj "/C=US/ST=State/L=City/O=MyOrg/OU=OrgUnit/CN=client"
openssl x509 -req -in ${CLIENT_CSR} -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${CLIENT_CRT} -days ${DAYS} -sha256

# Optional: Create a P12 client certificate for browsers
openssl pkcs12 -export -out ${CLIENT_P12} -inkey ${CLIENT_KEY} -in ${CLIENT_CRT} -certfile ${ROOT_CA_CRT} -password pass:clientpassword

# Output information
echo "Certificates generated in ${CERT_DIR}"
