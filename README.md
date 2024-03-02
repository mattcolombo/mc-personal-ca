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
* open the newly created `openssl-ca.cnf` file and change the default in the `[ ca_distinguished_name ]`. The values to change are the ones surrounded by `##`;
* run the [create-local-ca.sh](./rootCA/create-local-ca.sh). 

The output of the script is going to all be located in the [rootCA](./rootCA/):

* the root certificate `rootCA.crt`
* the private key `rootCA.key`
* a `txt` file with the passphrase for the private key, which will need to be used to sign certificates from here onwards.

> [!TIP]
> It is a good idea to keep the `openssl-ca.cnf` file created in the first step for the future: this is the reference file for your own CA, and will also be used when signing new certificates. Note that even if you are using the files in this repo also as a repo (e.g. in case you forked the repo) the `.gitignore` file is already taking care to not commit the root certificates keys, passwords and the specific config files (such as `openssl-ca.cnf`) used in your own specific CA. So you are safe to keep all of it there.

## Generating signed certificates

[this script](./create-signed-certificate.sh) which creates the CSR and signs a certificate with it using [this ca config](./openssl-ca.cnf) and [this server config](./openssl-srv.cnf)

## Automation of the certificate signing process

### Prerequisites

* Create a new variable group in the ADO pipeline library and add a secret variable with the password for the CA private key
* Add the root certificate and private key as secure files in the ADO pipeline library

### The actual pipeline

[this pipeline file](./.ado/create-signed-certificate.yaml)

> [!NOTE]
> The automation presented above can be implemented easily with any other automation tool that supports running a bash script, since most of the logic is self-contained in the [create-signed-certificate.sh](./create-signed-certificate.sh) script. An example of how this could look in GitHub Actions is provided in [this document](./doc/GH-Actions.md); note that this was created for an older and simpler version of the script, so to work with the current version it would need to be adapted somewhat. The main structure would still be the same though.

----------------

## How to generate certificates manually - TO BE FIXED

To run the certificate generation manually (once the root certificate and key have been generated as per the instructions in the previous section), simply ensure you have the script [create-signed-certificate.sh](./create-signed-certificate.sh) in the same folder as the root certificate and relative private key. This folder needs to be accessible by `bash`.

> [!WARNING] 
> The root certificate and key files need to be named `rootCA.crt` and `rootCA.key` for the script to work out of the box. If that is not the case, either rename the files or modify the script on line 61. Also, the root private key need should not be password protected. If that is the case again the command on line 61 needs to be modified.

Once all the files are in the correct place, modify if needed lines 25-27 to enter your default `Country`, `State` and `Locality` for the certificate (these could but don't necessarily have to match the ones in the Root CA generated before). As per the script they are specific to my own case.

Finally, simply run the script using as inputs the `Organization`, `Org Unit` and `Common Name` (hostname) required for the certificate as seen below. As noted above, `Country`, `State` and `Locality` are filled in by default by the script. If they need to change, please modify the defaults in the script itself.

```
create-signed-certificate.sh <organization> <org unit> <common name>
```

The script will create a folder called `certbundle` that contains the following items:
* the certificate generated in PEM format
* the private key in PEM format
* the certificate (including private key) in P12 format
* a text file with the password for the P12 file

> [!WARNING] 
> Since the folder is always called the same way, if you are generating multiple certificates you will need to move or rename the folder after each certificate is generated. This is not ideal, but since the script is meant primarily for use in a pipeline, this is the most convenient way since each pipeline run will anyway start from a clean slate.

## Automating the generation process

My own personal automation is hosted in a private Org in Azure DevOps. That is because I generally prefer ADO Pipelines over GitHub Actions (I find them more flexible and powerful; also I am more familiar with them). For an example of how a pipeline there could be set up, please refer to the pipeline file `create-signed-certificate.yaml` in the `.ado` folder.


