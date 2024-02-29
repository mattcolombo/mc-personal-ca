# Example automation using GitHub actions

Below is a sample GitHub action used to produce automatically a set of certificates as required. The action is triggered manually, and the user is required to add the `Organization`, `Org Unit` and `Common Name` (hostname) for the certificate.

## Prerequisites

Before starting we need to ensure to perform a few steps:

* Generate a personal rootCA (certificate and key) following this guide [Create your own Certificate Authority - Medium](https://priyalwalpita.medium.com/create-your-own-certificate-authority-47f49d0ba086) or this guide [Generate an Azure Application Gateway self-signed certificate with a custom root CA - MSFT Learn](https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates)
* Modify the script [create-signed-certificate.sh](/create-signed-certificate.sh) 25-27 to enter your default `Country`, `State` and `Locality` for the certificate (these could but don't necessarily have to match the ones in the Root CA generated before)
* Use base64 to encode the root certificate and private key, and add them to GitHub secrets called `ROOT_CA` and `ROOT_CA_KEY`; if the names are changed, be sure to adjust them in the pipeline code below

## GitHub action code

Create a folder called `.github/workflows` in your repository that contains the script for generating the certificates, and add a file with the below contents. Once pushed to the main branch, an Action will be available for running. The run will publish as a workflow artifact a bundle containing:
* the certificate generated in PEM format
* the private key in PEM format
* the certificate (including private key) in P12 format
* a text file with the password for the P12 file

```
name: Signed Certificate Creation
run-name: Creating a certificate signed by my own CA
on: 
  workflow_dispatch:
    inputs:
      org:
        description: 'Organization'
        required: true
        default: 'MCCORP'
      orgunit:
        description: 'Organizational Unit'
        required: true
        default: 'IT'
      cn:
        description: 'Common Name'
        required: true
        default: 'test.example.com'
jobs:
  Create-Upload-Certificate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Retrieve the CA and key and decode to files
        env:
          CA_BASE64: ${{ secrets.ROOT_CA }}
          CA_PKEY_BASE64: ${{ secrets.ROOT_CA_KEY }}
        run: |
          echo $CA_BASE64 | base64 --decode > rootCA.crt
          echo $CA_PKEY_BASE64 | base64 --decode > rootCA.key
      - name: Add execute permission to script
        run: chmod +x create-signed-certificate.sh
      - name: Create signed certificate
        run: ./create-signed-certificate.sh ${{ inputs.org }} ${{ inputs.orgunit }} ${{ inputs.cn }}
      - name: Upload certificate bundle as artifact (MUST be downloaded within 2 days)
        uses: actions/upload-artifact@v4
        with:
          name: ${{ inputs.cn }}-bundle
          path: ./certbundle
```

> [!CAUTION]
> The above pipeline is provided only as an example, and the script used there is an older version. Hence, for this to work with the current version of the scripts it would need to be adapted. Please refer to the Azure DevOps pipeline logic for the more up to date version.