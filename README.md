# mc-personal-ca

This repository contains the scripts and pipelines necessary to create certificates signed by my own personal CA, which is trusted by absolutely no one!

## Creating a personal Certificate Authority

fsfsd

## How to generate certificates manually

sdfgsdfgsdfgs

## Automating the generation process

My own personal automation is hosted in a private Org in Azure DevOps. That is because I generally prefer ADO Pipelines over GitHub Actions (I find them more flexible and powerful; also I am more familiar with them). For an example of how a pipeline there could be set up, please refer to the pipeline file `create-signed-certificate.yaml` in the `.ado` folder.

The same automation can also be implemented easily elsewhere since most of the logic is self-contained in a script. This means it could be run manually (as described above), or it could be automated in any tool one could desire, as long as said tool have the capability to run a bash script. An example of how this could look in GitHub Actions is provided in [this document](./doc/GH-Actions.md).
