# mc-personal-ca

This repository contains the scripts and pipelines necessary to create certificates signed by my own personal CA, which is trusted by absolutely no one!

## How to become a Certificate Authority

Becoming a Certificate Authority (CA) could not be more simple: all we need is to generate a self-signed certificate with a strong key (ideally password protected, since it will be used to sign all the other certificates) and then convince the world to trust you as a Certificate Authority. The second part is by far the most difficult part. 

Since convincing the world about anything, leave alone trusting some random person, is quite complicated and very tiring we will discuss here only the first part. That is actually relatively simple. Everything that was done (and documented) here is based on this quite excellent [guide](https://stackoverflow.com/questions/21297139/how-do-you-sign-a-certificate-signing-request-with-your-certification-authority/21340898#21340898) authored by [Chad Killingsworth](https://stackoverflow.com/users/1211524/chad-killingsworth) found on Stackoverflow. This is by far the most complete guide I was able to find. Some more simplified versions of the same process can be found in this Medium post [Create your own Certificate Authority - Medium](https://priyalwalpita.medium.com/create-your-own-certificate-authority-47f49d0ba086) or this guide from Microsoft [Generate an Azure Application Gateway self-signed certificate with a custom root CA - MSFT Learn](https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates). These however are quite simplified methods, and generate V1 SSL certificates, which do not include some of the more powerful features that are present in V3 SSL certificates, such as for example the use of Subject Alternative Names.

In the rest of this document we will explore how we can generate (manually, since this would usually be a one time activity) a self-signed root certificate and relative private key for our new personal CA, and then how to sign certificates using our new very own root certificate. For this there will be a script that allows to perform this process by hand, and the code for an Azure DevOps pipeline that allows to process this as an automated process by taking few parameters as input.

> [!CAUTION] 
> Since as noted above it may be problematic to convince the world to trust us as a CA, the certificates generated using the methods and scripts presented here should be used only for development purposes and at most internal testing; never for Production systems.

## Generating the root certificate and key

Generation of a root certificate and the related private key, which are essential to become a CA, is quite simple. Notice that it is quite important for the private key to be a good length and password protected, since that is the one that protects your identity as a CA.

The script [create-local-ca.sh](./rootCA/create-local-ca.sh) found in the [rootCA](./rootCA/) folder takes these two facts into consideration when creating the rootCA. The key is created with a length of 4096 bits (unlike the more usual 2048 used for most certificates) and is password protected, with the password generated randomly.

To create your very own root certificate and key, simply follow these steps:

* in the [rootCA](./rootCA/) folder, make a copy of the [tmpl-openssl-ca.cnf](./rootCA/tmpl-openssl-ca.cnf) file and name it `openssl-ca.cnf`;
* open the newly created `openssl-ca.cnf` file and change the default values in the `[ ca_distinguished_name ]`. The values to change are the ones surrounded by `##`;
* run the [create-local-ca.sh](./rootCA/create-local-ca.sh). 

The output of the script is going to all be located in the [rootCA](./rootCA/):

* the root certificate `rootCA.crt` with a default duration of 1024 days;
* the private key `rootCA.key`;
* a `txt` file with the passphrase for the private key, which will need to be used to sign certificates from here onwards.

At this point, if the certificates that will be generated with this local CA are going to be used locally for testing, it may be a good idea to add the `rootCA.crt` to your local truststore (e.g. the trusted root certificates in Windows, or whatever flavour of truststore your application or system is using). This will make sure that any certificates you will generate from here onwards will be trusted by your system or application and thus avoid TLS errors (or annoying messages in your browser about untrusted pages).

> [!TIP]
> The `openssl-ca.cnf` file created in the first step must be kept for the future: not only this is the reference file for your own CA, but it will also be used when signing new certificates. Note that even if you are using this repo (e.g. a fork of the original) the `.gitignore` file is already taking care to not commit the root certificates keys, passwords and the specific config files (such as `openssl-ca.cnf`) used in your own specific CA. So you are safe to keep all of it there.

## Generating signed certificates manually

Once the root certificate and key that will be used to sign subsequent certificates are created as per the [previous section](#generating-the-root-certificate-and-key), it's time to start creating your very own signed certificates.

To do this, follow these simple steps:

* in the root folder of the repo, make a copy of the [tmpl-openssl-srv.cnf](./tmpl-openssl-srv.cnf) file and give it some name that makes it clear which certificate it is referring to (e.g. `openssl-srv-testexamplecom.cnf`). Note that it is important that the extension be kept as `.cnf`;
* in the `*.cnf` file just created replace the values surrounded by `##` on lines 7 (this will determine the name of the private key that will be generated for your certificate), 15,18,21,24,27 and 30 (this will determine the subject for your certificate) and add the hostname to line 46 (replace `##CN##`);
* add any required Subject Alernative Names by adding lines at the bottom of the file in the format `DNS.# = hostname`
* run the script [create-signed-certificate.sh](./create-signed-certificate.sh) providing as input the common name (same as used to replace `##CN##` in the file above), the path to the file just created and the passphrase for the root private key.

The script will initially create a private key (not password protected this time) and certificate signing request (CSR) using the `.cnf` file provided; it will then sign the CSR with the root certificate and key, using as reference the `openssl-ca.cnf` file stored in the [rootCA](./rootCA/) folder and created at the time of the creation of the root certificate and key.

The output of the script is going to a folder named `certbundle-*` (where `*` is going to be the common name provided as input without the dots) and consists of:
* the certificate file in PEM format `*.crt` with default duration of 365 days (1 year);
* the relative private key in PEM format `*.key` (not encrypted);
* the certificate in a password protected `*.p12` file in PKCS12 format (including therefore the private key);
* a `*.txt` file containing the password for the `*.p12` file.

The `certbundle-*` folder is also excluded from being tracked in git so can be safely kept here.

> [!TIP]
> We can generate multiple certificates by simply creating several `.cnf` files and running the script multiple times in succession. Since the output folder includes the common name (though without `.` for simplicity) they can all be stored here as long as needed.

> [!WARNING]
> Due to how the `openssl-ca.cnf` is written and how the scripts work, it is important to maintain the current folder and file structure and naming. In particular the rootCA folder **must** contain the `rootCA.crt`, `rootCA.key` and `openssl-ca.cnf` files, and the script for the certificate generation must be run from a directory that contains the aforementioned `rootCA` directory in it. Additionally, the `db` folder must also be present and contain at least a `serial.txt` file with some number in it and an empty `index.txt` file. This will then allow all the scripts to work. If for some reason you wish to change this structure, please take care to modify both the scripts and the `openssl-ca.cnf` (lines 16 to 21) to reflect the desired structure.

## A note on security

As we have seen above, all the script are generating passwords (for the root certificate private key and then for the PKCS12 format certificate) and storing them in a `.txt` file next to the item they belong to. This is of course not very secure.

This was done this way since this whole process is meant to be used locally and for personal use to generate testing certificates. This is **NOT** meant to stand up a whole PKI operation. If that is the case, then some more attention will need to be placed onto how the generation and, more importantly, distribution of the certificates and relative passwords needs to happen. An example could be to distribute the certificate (PKCS12 format only) over email and the password over some different messaging system. Even better automatically upload the certificates and related passwords in some kind of secret storage and management vault (e.g. Azure KeyVault or Hashicorp Vault) that only the requestor has access to. 

Additionally in this case, more care would need to be taken in how to store and manage the root certificate, private keys and most importantly passwords.

## Automation of the certificate signing process  --  TBC

### Prerequisites

* Create a new variable group in the ADO pipeline library and add a secret variable with the password for the CA private key
* Add the root certificate and private key as secure files in the ADO pipeline library

### The actual pipeline

[this pipeline file](./.ado/create-signed-certificate.yaml)

> [!NOTE]
> The automation presented above can be implemented easily with any other automation tool that supports running a bash script, since most of the logic is self-contained in the [create-signed-certificate.sh](./create-signed-certificate.sh) script. An example of how this could look in GitHub Actions is provided in [this document](./doc/GH-Actions.md); note that this was created for an older and simpler version of the script, so to work with the current version it would need to be adapted somewhat. The main structure would still be the same though.
