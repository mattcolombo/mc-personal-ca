# mc-personal-ca

This repository contains the scripts and pipelines necessary to create certificates signed by my own personal CA, which is trusted by absolutely no one!

## Creating a personal Certificate Authority

Instructions on how to create your very own personal Certificate Authority can be found either at this Medium post [Create your own Certificate Authority - Medium](https://priyalwalpita.medium.com/create-your-own-certificate-authority-47f49d0ba086) or this guide from Microsoft [Generate an Azure Application Gateway self-signed certificate with a custom root CA - MSFT Learn](https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates). I followed the first one, so I cannot vouch for the correctness of the second, but they are pretty much the same thing anyway so either should work fine.

## How to generate certificates manually

To run the certificate generation manually (once the root certificate and key have been generated as per the instructions in the previous section), simply ensure you have the script [create-signed-certificate.sh](./create-signed-certificate.sh) in the same folder as the root certificate and relative private key. This folder needs to be accessible by `bash`.

:warning: **Note**: the root certificate and key files need to be named `rootCA.crt` and `rootCA.key` for the script to work out of the box. If that is not the case, either rename the files or modify the script on line 61. Also, the root private key need should not be password protected. If that is the case again the command on line 61 needs to be modified.

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

:warning: **Note**: since the folder is always called the same way, if you are generating multiple certificates you will need to move or rename the folder after each certificate is generated. This is not ideal, but since the script is meant primarily for use in a pipeline, this is the most convenient way since each pipeline run will anyway start from a clean slate.

## Automating the generation process

My own personal automation is hosted in a private Org in Azure DevOps. That is because I generally prefer ADO Pipelines over GitHub Actions (I find them more flexible and powerful; also I am more familiar with them). For an example of how a pipeline there could be set up, please refer to the pipeline file `create-signed-certificate.yaml` in the `.ado` folder.

The same automation can also be implemented easily elsewhere since most of the logic is self-contained in a script. This means it could be run manually (as described above), or it could be automated in any tool one could desire, as long as said tool have the capability to run a bash script. An example of how this could look in GitHub Actions is provided in [this document](./doc/GH-Actions.md).

## Adding SANs to the cert

https://alexanderzeitler.com/articles/Fixing-Chrome-missing_subjectAltName-selfsigned-cert-openssl/ -- currently used
https://stackoverflow.com/questions/21297139/how-do-you-sign-a-certificate-signing-request-with-your-certification-authority/21340898#21340898 -- need to be checked 
