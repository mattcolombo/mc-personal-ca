#!/bin/bash

print-usage () {
    echo "Usage: create-local-ca.sh <private_key_password>"
}

# making sure that keytool and openssl are installed
check-commands () {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        exit 1
    fi
}

check-commands openssl

# checking that the number of arguments is the correct one. Printing usage if not
if [[ "$#" -ne 1 ]]; then
    echo "Illegal number of parameters"
    print-usage
    exit 1
fi

KEYPASS="$1"

echo "Creating the local CA with validity of 1024 days using the defaults from openssl-ca.cnf"
openssl req -batch -x509 -config ./openssl-ca.cnf -days 1024 -newkey rsa:4096 -sha256 -passout "pass:$KEYPASS" -out rootCA.crt -outform PEM

echo "- validating that the CSR and key match"
#validation steps
KEYDGS=$(openssl rsa -noout -modulus -in rootCA.key -passin "pass:$KEYPASS" | openssl sha256)
CRTDGS=$(openssl x509 -noout -modulus -in rootCA.crt | openssl sha256)

if [[ "$KEYDGS" == "$CRTDGS" ]]
then
echo "  root certificate and key match... operation is successful"
echo "    $KEYDGS"
echo "    $CRTDGS"
else
echo "  signing request and key don't match.... removing the incorrect files"
echo "    $KEYDGS"
echo "    $CRTDGS"
rm "rootCA.key"
rm "rootCA.crt"
exit 1
fi