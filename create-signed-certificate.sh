#!/bin/bash

print-usage () {
    echo "Usage: create-signed-certificate.sh <common_name> <cnf_file> <rootCAkey_password>"
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
if [[ "$#" -ne 3 ]]; then
    echo "Illegal number of parameters"
    print-usage
    exit 1
fi

CN="$1"
CONF="$2"
KEYPASS="$3"

echo "Creating the certificate private key and signing request"
openssl req -batch -config "$CONF" -newkey rsa:2048 -sha256 -nodes -out "$CN.csr" -outform PEM

echo "- validating that the CSR and key match"
#validation steps
KEYDGS=$(openssl rsa -noout -modulus -in "$CN.key" | openssl sha256)
CSRDGS=$(openssl req -noout -modulus -in "$CN.csr" | openssl sha256)

if [[ "$KEYDGS" == "$CSRDGS" ]]
then
echo "  signing request and key match... can proceed with certificate creation"
echo "    $KEYDGS"
echo "    $CSRDGS"
else
echo "  signing request and key don't match.... quitting"
echo "    $KEYDGS"
echo "    $CSRDGS"
rm "$CN.key"
rm "$CN.csr"
exit 1
fi

echo " "
echo "---------"
echo " "

echo "Signing the requested certificate"

openssl ca -batch -config ./rootCA/openssl-ca.cnf -policy signing_policy -extensions signing_req -passin "pass:$KEYPASS" -out "$CN.crt" -notext -rand_serial -infiles "$CN.csr"
rm "$CN.csr"

echo "- validating that the certificate and key match"
#validation steps
CRTDGS=$(openssl x509 -noout -modulus -in "$CN.crt" | openssl sha256)

if [[ "$KEYDGS" == "$CRTDGS" ]]
then
echo "  certificate and key match... creation was successful"
echo "    $KEYDGS"
echo "    $CSRDGS"
else
echo "  certificate and key don't match.... quitting"
echo "    $KEYDGS"
echo "    $CSRDGS"
rm "$CN.key"
rm "$CN.crt"
exit 1
fi

P12PASS=$(openssl rand -hex 8)
openssl pkcs12 -export -out "$CN.p12" -in "$CN.crt" -inkey "$CN.key" -passout pass:"$P12PASS"
echo "$P12PASS" > "$CN.p12-pass.txt"

DIR="certbundle-$(echo $CN | tr -d '.')"
echo "Certificate creation completed; certificate and key can be found in the $DIR folder"
mkdir $DIR
mv "$CN.key" $DIR
mv "$CN.crt" $DIR
mv "$CN.p12" $DIR
mv "$CN.p12-pass.txt" $DIR
rm *.pem
