# mc-personal-ca

This repository contains the scripts and pipelines necessary to create certificates signed by my own personal CA, which is trusted by absolutely no one!

While the automation is going to be ultimately hosted in Azure DevOps in a private project, which means useable only by me and people I give access to, this could be implemented easily elsewhere since the logic is self-contained in a script. This means it could be run manually, or it could be automated in any tool one could desire. An example of how this could look in GitHub Actions is provided in [this document](./doc/GH-Actions.md).
