#!/bin/bash -e
KEY_FILE="self_signed.pem"
CERT_FILE="self_signed.cert"
HOST="wp.aws101.org"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${KEY_FILE}" -out "${CERT_FILE}" -subj "/CN=${HOST}/O=${HOST}"


kubectl -n clase11  create secret tls "${HOST}" --key "${KEY_FILE}" --cert "${CERT_FILE}"
