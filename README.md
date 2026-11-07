# AAS CodeSign | InnoSetup | Docker
Azure Artifact Signing | CodeSign | InnoSetup | Docker | jsign

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Description
Are you distributing Windows Software outside of the Microsoft Store? For your users best experience and confidence, your applications should shipped as a windows installer and be codesigned.

### Codesigning
This example shows how to codesign using 
- [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/)
- a codesigning certificate `.pfx`

Codesigning is using [jsign](https://github.com/ebourg/jsign) in a Docker Container [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign). This allows codesigning to be performed on a host machine running on either Windows, macOS or Linux.

#### Requirements

- Set up Codesigning with one of the following
  - [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/)  
    To [get you started]((https://learn.microsoft.com/en-us/azure/artifact-signing/quickstart)) have a look at the included [docs](./docs/).  
    You'll find some useful links and archived Web content there.
  - Codesign certificate `.pfx`
- Codesigning `.json`configuration files
  - See the [provided template configuration files](./docs/)

- Have [Docker](https://www.docker.com/products/docker-desktop/) up and running

### InnoSetup
This example shows how build a *(codesigned)* windows installer using [InnoSetup](https://jrsoftware.org/isinfo.php).  
Creating the windows installer is being done in a Docker Container [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup). This allows creating the windows installer on a host machine running on either Windows, macOS or Linux.

#### Requirements

- Optional: Set up Codesigning
- Have [Docker](https://www.docker.com/products/docker-desktop/) up and running


## Docker Images

While the included example project is written with [Xojo](https://www.xojo.com/) you can use this approach with any other development environment.

### `jotools/codesign`

Please refer to the [Documentation](./dockerimage/codesign/) for the provided [Docker Image `jotools/codesign`](./dockerimage/codesign/). It includes information about how to set it all up, along with a codesigning example.

### `jotools/innosetup`

Please refer to the [Documentation](./dockerimage/innosetup/) for the provided [Docker Image `jotools/innosetup`](./dockerimage/innosetup/). It includes information about how to set it all up, along with an example to create a *(codesigned)* Windows installer.

> **Note**  
> Version 3.0.0 of the Docker Image `jotools/innosetup` includes InnoSetup 7. Please have a look at the [Upgrade Notes](./dockerimage/innosetup/README.md#upgrade-notes).

## Xojo Example Project

This repository includes a Xojo Example Project `AAS CodeSign InnoSetup.xojo_project` which uses
- a Post Build Script `CodeSign` to codesign the Windows builds using [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/) *(or a codesign certificate `.pfx`)*
  - using the Docker Container [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign) to perform the codesigning using [jsign](https://github.com/ebourg/jsign)
- a Post Build Script `CreateZIP` to package the built and codesigned application in a `.zip`
- a Post Build Script `InnoSetup` to build a *(codesigned)* windows installer
  - using the Docker Container [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup) to create the windows installer with [InnoSetup](https://jrsoftware.org/isinfo.php)

This allows the Windows application to be built and codesigned with the Xojo IDE running on all Windows, macOS or Linux.

### ScreenShots

Xojo Example Project: AAS CodeSign | InnoSetup | Docker  
![ScreenShot: Xojo Example Project: AAS CodeSign | InnoSetup | Docker](screenshots/xojo-example-project.png?raw=true)

Code Signature *(Codesigned with Xojo IDE running on macOS)*
![ScreenShot: Code Signature - Codesigned with Xojo IDE running on macOS](screenshots/code-signature.png?raw=true)

Codesigned Windows Installer *(Created and codesigned with Xojo IDE running on macOS)*
![ScreenShot: Codesigned Windows Installer - Created and codesigned with Xojo IDE running on macOS](screenshots/codesigned-Installer.png?raw=true)


## Xojo
### Requirements
[Xojo](https://www.xojo.com/) is a rapid application development for Desktop, Web, Mobile & Raspberry Pi.  

The Desktop application Xojo example project `AAS CodeSign InnoSetup.xojo_project` and its Post Build Scripts are using:
- Xojo 2026r1.2
- API 2

### How to use in your own Xojo project?

<details>

<summary>CodeSign (Azure Artifact Signing | PFX)</summary>

1. Set up the local configuration files for CodeSign.  
   The Post Build Script(s) expect the following `.json` configuration file(s):
   - [Azure Artifact Signing](./docs/aas-codesign/)
   - [Codesigning Certificate `.pfx`](./docs/pfx-codesign/)
2. Create a Post Build Script in your project and copy-and-paste the example Post Build Script `CodeSign` provided in `AAS CodeSign InnoSetup.xojo_project`
3. Make sure the Post Build Script `CodeSign` runs after the Step 'Windows: Build'
4. Read the comments in the provided Post Build Script, modify it according to your needs  
   The default settings are:
   - use the Docker Container [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign)
     - *if you're using the `InnoSetup` step as well, then change it to use the Docker Container [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)* so that you don't need having two different Docker Images taking up space on your machine
   - Codesign Final and Beta Builds
     - *no Codesigning for Alpha- and Development Builds*
   - Codesign all `.exe` and `.dll` files for Final Builds
     - *Codesign just all `.exe`, but not the `.dll` files for Beta/Alpha/Development Builds*

</details>

<details>

<summary>CreateZIP</summary>

1. Create a Post Build Script in your project and copy-and-paste the example Post Build Script `CreateZIP` provided in `AAS CodeSign InnoSetup.xojo_project`
2. Make sure this Post Build Script runs after the Step 'Windows: Build' *(and after `CodeSign` to ensure you zip the codesigned application)*
3. Read the comments in the provided Post Build Script, modify it according to your needs

</details>

<details>

<summary>InnoSetup</summary>

1. Copy the folder and file `_build/innosetup_universal.iss` to your project location
   - *this is a universal InnoSetup script which should fit basic Xojo built applications*
     - *it's prepared for all Windows Build Targets (WIN32, WIN64, ARM64)*
     - *it uses parameters so that it can be configured from within the Post Build Script*
   - *or use your own InnoSetup script*
2. Optional *(only if you want to codesign the Windows Installers)*:  
   Set up the local configuration files for CodeSign.  
   The Post Build Script(s) expect the following `.json` configuration file(s):
   - [Azure Artifact Signing](./docs/aas-codesign/)
   - [Codesigning Certificate `.pfx`](./docs/pfx-codesign/)
3. Create a Post Build Script in your project and copy-and-paste the example Post Build Script `InnoSetup` provided in `AAS CodeSign InnoSetup.xojo_project`
4. Make sure this Post Build Script runs after the Step 'Windows: Build' *(and after `CodeSign` to ensure you include the codesigned application in the windows installer)*
5. Read the comments in the provided Post Build Script, modify it according to your needs, e.g.:
   -  change the value of `sAPP_PUBLISHER_URL` to your own website
   -  change the value of `bCODESIGN_ENABLED` to `False` if you want to create a Windows Installer without CodeSigning. If this value is `True`, the Post Build Script will expect Codesigning to be available and print an Information Message if it's configuration is not found.
6. The example Post Build Script is designed to be quite generic and using the provided Universal InnoSetup Script will:
   - use the Docker Container [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)
   - create a Windows Installer for Final and Beta Builds
     - *no Windows Installer for Alpha- and Development Builds*
   - pick up necessary information from the Xojo Project *(so make sure you've filled out the values in the Xojo IDE under 'Build Settings: Windows)*, e.g.
     - `App.ProductName`, `App.CompanyName`
     - Filename of the application's `.exe`
   - pick up the configuration of `CodeSign` *(if `bCODESIGN_ENABLED = True`)*
     - if available, it codesigns the (Un)Installer
     - if not found, it outputs an Info, proceeds with ignoring codesigning and just creates an installer

</details>

## Security Warning

The Post Build Scripts in the example project are intended as an example to demonstrate the functionality. They allow to retrieve sensitive information *(such as a Client Secret or Certificate Password)* from a plaintext `.json` configuration file, which is **not secure**.

However, the provided Post Build Scripts also support retrieving credentials from a Secret Storage and run the Docker Container with the corresponding Environment Variables, omitting the secrets in the `.json` configuration files. It's highly recommended to use that approach.

If using similar logic in a production environment, make sure to implement a secure method for managing secrets to protect sensitive information.


<details>

<summary>Security Risks</summary>

Storing secrets in plaintext files poses significant security risks, including:  
- **Exposure to unauthorized users** if file permissions are not properly set.  
- **Inclusion in backups or version control** (e.g., Git), leading to unintentional leaks.  
- **Easy access for malware or attackers** on a compromised system.

</details>

<details>

<summary>Secure Alternatives</summary>

Instead of storing secrets in a `.json` configuration file, consider these more secure approaches:  

1. Use OS-Level Secret Storage  
   - **macOS**: Store secrets in **Keychain Access** and retrieve them using the `security` CLI tool.  
   - **Linux**: Use **GNOME Keyring** or **KWallet** to securely store and retrieve secrets.  
   - **Windows**: Store credentials in **Windows Credential Manager** and access them via PowerShell.  

2. Use a Secrets Manager  
   - Cloud providers like **AWS Secrets Manager, Azure Key Vault, or GCP Secret Manager** offer secure, centralized secret storage with access control.  
   - Local alternatives like **1Password CLI, Bitwarden CLI, or HashiCorp Vault** allow secure retrieval of secrets at runtime.  

</details>



## About
Juerg Otter is a long term user of Xojo and working for [CM Informatik AG](https://cmiag.ch/). Their Application [CMI LehrerOffice](https://cmi-bildung.ch/) is a Xojo Design Award Winner 2018. In his leisure time Juerg provides some [bits and pieces for Xojo Developers](https://www.jo-tools.ch/).

### Contact
[![E-Mail](https://img.shields.io/static/v1?style=social&label=E-Mail&message=xojo@jo-tools.ch)](mailto:xojo@jo-tools.ch)
&emsp;&emsp;
[![Follow on Facebook](https://img.shields.io/static/v1?style=social&logo=facebook&label=Facebook&message=juerg.otter)](https://www.facebook.com/juerg.otter)
&emsp;&emsp;
[![Follow on Twitter](https://img.shields.io/twitter/follow/juergotter?style=social)](https://twitter.com/juergotter)

### Donation
Do you like this project? Does it help you? Has it saved you time and money?  
You're welcome - it's free... If you want to say thanks I'd appreciate a [message](mailto:xojo@jo-tools.ch) or a small [donation via PayPal](https://paypal.me/jotools).  

[![PayPal Dontation to jotools](https://img.shields.io/static/v1?style=social&logo=paypal&label=PayPal&message=jotools)](https://paypal.me/jotools)
