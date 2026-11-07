# Docker Image

The Docker Image is based on Debian and has the following components installed:
- A couple of required Libraries
  - curl, jq, Java Runtime *(default-jre-headless)*, wine *(64-bit)*
- [jsign](https://github.com/ebourg/jsign)  
  Authenticode signing tool in Java
- `aas-codesign.sh` and `pfx-codesign.sh`  
  Custom Shell Script used for Windows Code Signing using Azure Artifact Signing or a codesign certificate `.pfx`   
  - Usage:  
    `aas-codesign.sh [FILE] [PATTERN] [@FILELIST]...`  
    `pfx-codesign.sh [FILE] [PATTERN] [@FILELIST]...`  
  - Documentation: [jsign - Command Line Tool: `[FILE] [PATTERN] [@FILELIST]...`](https://ebourg.github.io/jsign/)
- [InnoSetup 7](https://jrsoftware.org/isinfo.php) *(64-bit edition)*  
  Inno Setup is a free installer for Windows programs
  - This is a windows application, so it runs under [wine](https://www.winehq.org)
  - This Docker Image includes helper scripts:
    - `iscc.sh '[InnoSetup Parameters]'`  
      Invokes InnoSetup running under wine
    - `aas-codesign.bat` | `pfx-codesign.bat`  
      Allows InnoSetup (Un)Installer to be codesigned using Azure Artifact Signing or a codesign certificate `.pfx`
  - Documentation: [InnoSetup: Help file](https://jrsoftware.org/ishelp/)

### Build Docker Image
<details>

<summary>Docker Image: Build instructions</summary>

To build it locally as `mycompany/innosetup` on the host machine where you intend to use it:

**Intel 64bit**
```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/amd64 -t mycompany/innosetup .
```

**ARM 64bit**
```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/arm64 -t mycompany/innosetup .
```

To create a multi arch Docker Image, push it to Docker Hub and tag it as 'latest':

```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/amd64 -t mycompany/innosetup:1.0.0-amd64 .
docker build --no-cache --platform=linux/arm64 -t mycompany/innosetup:1.0.0-arm64 .

docker push mycompany/innosetup:1.0.0-amd64
docker push mycompany/innosetup:1.0.0-arm64

docker buildx imagetools create -t mycompany/innosetup:1.0.0 -t mycompany/innosetup:latest mycompany/innosetup:1.0.0-amd64 mycompany/innosetup:1.0.0-arm64
```

</details>

### Docker Hub

The built Docker Image is available on Docker Hub: [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)

## Upgrade Notes

### Version 3.0.0: InnoSetup 7

The Docker Image now includes [InnoSetup 7](https://jrsoftware.org/files/is7-whatsnew.htm) *(previously: InnoSetup 6)*.  
The usage of the Docker Image is unchanged *(entry points, parameters, mounts and environment variables)*.

- **Your own InnoSetup Scripts**  
  InnoSetup 7 is a new major version. Please check the [What's New in Inno Setup 7](https://jrsoftware.org/files/is7-whatsnew.htm) for changes that may affect your own `.iss` scripts, such as:
  - Pascal Scripting: `EnableFsRedirection` has been removed, new built-in types *(e.g. `NativeInt`, `HWND`)*, changes to `FloatToStr`, `IsWildcard` and `CreateCustomForm`
  - changed defaults: `AppVerName` *(no more word "version")*, `TimeStampsInUTC=yes`
  - `.isl` files with `#` lines and invalid characters in `.iss`/`.isl` files are now an error
- **64-bit Installer**  
  InnoSetup 7 can create 64-bit installers with `SetupArchitecture=x64`. The universal InnoSetup script `_build/innosetup_universal.iss` of the example project creates a 64-bit installer for 64-bit (Intel) builds.  
  If you keep using a copy of the previous version of the universal InnoSetup script, a 32-bit installer will be created *(just as before)*. InnoSetup 7 will show a harmless warning: `Function "GetFileProductVersion" has been renamed. Use "GetFileProductVersionString" instead.`
- **Codesigning errors**  
  If codesigning with `aas-codesign.bat` or `pfx-codesign.bat` fails *(or times out)*, InnoSetup fails too.
- **Internal changes** *(only relevant if you're using `wine` in the Docker Container directly)*  
  The wine prefix is now 64-bit, and InnoSetup is installed in `C:\Program Files\Inno Setup 7\` *(environment variable `ISCC_EXE`)*.
- **wine output**  
  wine debug output is disabled by default (`WINEDEBUG=-all`). To troubleshoot, run the Docker Container with e.g. `-e WINEDEBUG=fixme-all`.


## Documentation

Please refer to the documentation of the included tools:

- [InnoSetup: Help file](https://jrsoftware.org/ishelp/)
- [jsign - Command Line Tool: `[FILE] [PATTERN] [@FILELIST]...`](https://ebourg.github.io/jsign/)


## Windows Code Signing

You can use this Docker Image to do Windows Code Signing using [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/) or a codesign certificate `.pfx`.

Please refer to the examples of the Docker Image [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign).

> **Note**  
> Only use this Docker Image to build windows installers using [InnoSetup](https://jrsoftware.org/isinfo.php).  
> If you intend to only use codesigning *(without creating windows installers)*, head over to the smaller Docker Image [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign).  


## Examples

> **Note**  
> InnoSetup is running as a windows application.  
> So it's parameters need to be in windows style.  
> The drive letter `Z:\` will be the Docker Container's root `/`.  
> So `Z:\data` will be the mounted `/data`.


### Codesigning Requirements

> **Note**  
> You can skip the Configuration for Codesigning if you
> just want to build a windows installer without codesigning.

<details>

<summary>Configuration: Azure Artifact Signing</summary>

### Azure Artifact Signing

#### Configuration

Create the following two `.json` files on your host machine:

**`azure.json`**  
```
{
  "TenantId": "[Azure Tenant Id]",
  "ClientId": "[Azure Client Id]",
  "ClientSecret": "[Azure Client Secret]"
}
```

**`acs.json`**  
```
{
  "Endpoint": "https://weu.codesigning.azure.net",
  "CodeSigningAccountName": "[ACS Code Signing Account Name]",
  "CertificateProfileName": "[ACS Certificate Profile Name]"
}
```

And mount them into the following location when running the Docker Container:  
```
/etc/aas-codesign/azure.json
/etc/aas-codesign/acs.json
```

Instead of mounting the two `.json` files, you can also provide the configuration via Environment Variables:  
```
AZURE_TENANT_ID=[Azure Tenant Id]
AZURE_CLIENT_ID=[Azure Client Id]
AZURE_CLIENT_SECRET=[Azure Client Secret]
ACS_ENDPOINT=https://weu.codesigning.azure.net
ACS_ACCOUNT_NAME=[ACS Code Signing Account Name]
ACS_CERTIFICATE_PROFILE_NAME=[ACS Certificate Profile Name]
```

#### Timestamp Server

The Timestamp Server will be automatically chosen by jsign.  
To change it you can set the Environment Variables:  
```
TIMESTAMP_SERVER=http://timestamp.domain.org
TIMESTAMP_MODE=[RFC3161|Authenticode]
```

</details>

<details>

<summary>Configuration: Codesign certificate .pfx</summary>

### Codesign certificate .pfx

#### Configuration

Create the following `.json` file on your host machine:

**`pfx.json`**  
```
{
  "Password": "pfx-password",
  "TimestampServer": "http://timestamp.digicert.com",
  "TimestampMode": "Authenticode"
}
```

Have your codesign certificate `certificate.pfx` located on your host machine.

Mount them into the following location when running the Docker Container:  
```
/etc/pfx-codesign/pfx.json
/etc/pfx-codesign/certificate.pfx (Note: always required)
```

Instead of mounting the `.json` file, you can also provide the configuration via Environment Variable:  
```
PFX_PASSWORD=[PFX Password]
TIMESTAMP_SERVER=http://timestamp.domain.org
TIMESTAMP_MODE=[RFC3161|Authenticode]
```

</details>


### Create a windows installer using InnoSetup with `iscc.sh`

The included Shell Script `iscc.sh` is a helper script which will
- run [InnoSetup](https://jrsoftware.org/isinfo.php) under [wine](https://www.winehq.org)
- let you create a *(codesigned)* installer using the provided `aas-codesign.bat` or `pfx-codesign.bat`, which will call `aas-codesign.sh` or `pfx-codesign.sh` in the linux environment to
  - pick up the configuration from Environment Variables or the mounted `.json` files
  - perform the Windows Code Signing using [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/) or a codesigning certificate with [jsign](https://github.com/ebourg/jsign)

#### Example: Docker Run - InnoSetup

<details>

<summary>InnoSetup | Codesigning using Azure Artifact Signing</summary>

The following example will
- run the Docker Image [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)
- use Azure Artifact Signing configuration from `.json` files stored on the host machine
- mount a folder on the host machine into `/data`  
  that should include
  - the application to be packaged in a windows installer
  - the InnoSetup script `my-installer.iss`
- use entry point `iscc.sh`
- run InnoSetup to create a codesigned windows installer

```
docker run \
    --rm \
    -v /local/path/to/acs.json:/etc/aas-codesign/acs.json \
    -v /local/path/to/azure.json:/etc/aas-codesign/azure.json \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint iscc.sh \
    jotools/innosetup \
    '"/SCodeSignScript=Z:/usr/local/bin/aas-codesign.bat \$f" /O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'
```

The following example will
- use the locally stored Azure Artifact Signing configuration files `acs.json` and `azure.json`
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually create a codesigned windows installer, e.g.:  
    `iscc.sh '"/SCodeSignAAS=Z:/usr/local/bin/aas-codesign.bat \$f" /O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -v /local/path/to/acs.json:/etc/aas-codesign/acs.json \
    -v /local/path/to/azure.json:/etc/aas-codesign/azure.json \
    -v /local/path/to/build-folder:/data \
    jotools/innosetup
```
</details>

<details>

<summary>InnoSetup | Codesigning using `.pfx`</summary>

The following example will
- run the Docker Image [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)
- use a codesigning certificate `.pfx` and configuration `pfx.json` stored on the host machine
- mount a folder on the host machine into `/data`  
  that should include
  - the application to be packaged in a windows installer
  - the InnoSetup script `my-installer.iss`
- use entry point `iscc.sh`
- run InnoSetup to create a codesigned windows installer

```
docker run \
    --rm \
    -v /local/path/to/pfx.json:/etc/pfx-codesign/pfx.json \
    -v /local/path/to/my-certificate.pfx:/etc/pfx-codesign/certificate.pfx \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint iscc.sh \
    jotools/innosetup \
    '"/SCodeSignScript=Z:/usr/local/bin/pfx-codesign.bat \$f" /O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'
```

The following example will
- use a codesigning certificate `.pfx` and configuration `pfx.json` stored on the host machine
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually create a codesigned windows installer, e.g.:  
    `iscc.sh '"/SCodeSignScript=Z:/usr/local/bin/pfx-codesign.bat \$f" /O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -v /local/path/to/pfx.json:/etc/pfx-codesign/pfx.json \
    -v /local/path/to/my-certificate.pfx:/etc/pfx-codesign/certificate.pfx \
    -v /local/path/to/build-folder:/data \
    jotools/innosetup
```
</details>

<details>

<summary>InnoSetup | without codesigning</summary>

The following example will
- run the Docker Image [`jotools/innosetup`](https://hub.docker.com/r/jotools/innosetup)
- mount a folder on the host machine into `/data`  
  that should include
  - the application to be packaged in a windows installer
  - the InnoSetup script `my-installer.iss`
- use entry point `iscc.sh`
- run InnoSetup to create a windows installer

```
docker run \
    --rm \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint iscc.sh \
    jotools/innosetup \
    '/O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'
```

The following example will
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually create a windows installer, e.g.:  
    `iscc.sh '/O"Z:/data" /Dsourcepath="Z:/data/My Windows Application" "Z:/data/my-installer.iss"'`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -v /local/path/to/pfx.json:/etc/pfx-codesign/pfx.json \
    -v /local/path/to/my-certificate.pfx:/etc/pfx-codesign/certificate.pfx \
    -v /local/path/to/build-folder:/data \
    jotools/innosetup
```
</details>

## Security Warning

The provided Scripts `aas-codesign.sh` and `pfx-codesign.sh` allow retrieving sensitive information *(such as a Client Secret or Certificate Password)* from a plaintext `.json` configuration file, which is **not secure**.

That's just intended for demonstration and testing purposes only. If using similar logic in a production environment, implement a secure method for managing secrets to protect sensitive information.

Retrieve the secrets from a secure storage, and run the Docker Container from the script with the corresponding Environment Variables, omitting the secrets in the `.json` configuration files.

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

3. Use GitHub Actions Secrets *(for CI/CD Pipelines)*  
- If using this Docker Container in **GitHub Actions**, store secrets securely in **GitHub Secrets**.  
- Reference secrets in workflows using `${{ secrets.MY_SECRET }}` instead of storing them in the repository.  

</details>
