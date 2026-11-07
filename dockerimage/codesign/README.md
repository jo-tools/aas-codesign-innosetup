# Docker Image

The Docker Image is based on Debian and has the following components installed:
- A couple of required Libraries
  - curl, jq, Java Runtime *(default-jre-headless)*
- [jsign](https://github.com/ebourg/jsign)  
  Authenticode signing tool in Java
- `aas-codesign.sh` and `pfx-codesign.sh`  
  Custom Shell Script used for Windows Code Signing using Azure Artifact Signing or a codesign certificate `.pfx`   
  - Usage:  
    `aas-codesign.sh [FILE] [PATTERN] [@FILELIST]...`  
    `pfx-codesign.sh [FILE] [PATTERN] [@FILELIST]...`  
  - Documentation: [jsign - Command Line Tool: `[FILE] [PATTERN] [@FILELIST]...`](https://ebourg.github.io/jsign/)


### Build Docker Image

<details>

<summary>Docker Image: Build instructions</summary>

To build it locally as `mycompany/codesign` on the host machine where you intend to use it:

**Intel 64Bit**
```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/amd64 -t mycompany/codesign .
```

**ARM 64Bit**
```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/arm64 -t mycompany/codesign .
```

To create a multi arch Docker Image, push it to Docker Hub and tag it as 'latest':

```
cd /path/to/folder/with/dockerfile
docker build --no-cache --platform=linux/amd64 -t mycompany/codesign:1.0.0-amd64 .
docker build --no-cache --platform=linux/arm64 -t mycompany/codesign:1.0.0-arm64 .

docker push mycompany/codesign:1.0.0-amd64
docker push mycompany/codesign:1.0.0-arm64

docker buildx imagetools create -t mycompany/codesign:1.0.0 -t mycompany/codesign:latest mycompany/codesign:1.0.0-amd64 mycompany/codesign:1.0.0-arm64
```

</details>


### Docker Hub

The built Docker Image is available on Docker Hub: [`jotools/codesign`](https://hub.docker.com/r/jotools/codesign)

## Windows Code Signing 

You can use this Docker Image to do Windows Code Signing using [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/) or with a codesign certificate `.pfx`.

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

## Examples

<details>

<summary>Code Signing using Azure Artifact Signing</summary>

### Code Signing using `aas-codesign.sh`

The included Shell Script `aas-codesign.sh` is a helper script which will
- pick up the configuration from Environment Variables or the mounted `.json` files
- perform the Windows Code Signing using [Azure Artifact Signing](https://azure.microsoft.com/en-us/products/artifact-signing/) with [jsign](https://github.com/ebourg/jsign)

#### Example: Docker Run - CodeSign

The following example will
- run the Docker Image [jotools/codesign](https://hub.docker.com/r/jotools/codesign)
- use configuration from `.json` files stored on the host machine
- mount a folder on the host machine into `/data`
- use entry point `aas-codesign.sh`
- codesign all `.exe`'s and `.dll`'s in `/data` *(recursively)*

```
docker run \
    --rm \
    -v /local/path/to/acs.json:/etc/aas-codesign/acs.json \
    -v /local/path/to/azure.json:/etc/aas-codesign/azure.json \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint aas-codesign.sh \
    jotools/codesign \
    "./**/*.exe" "./**/*.dll"
```

The same example, but
- use a different Timestamp Server *(set via Environment Variable)*

```
docker run \
    --rm \
    -e TIMESTAMP_SERVER=http://timestamp.digicert.com \
    -v /local/path/to/acs.json:/etc/aas-codesign/acs.json \
    -v /local/path/to/azure.json:/etc/aas-codesign/azure.json \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint aas-codesign.sh \
    jotools/codesign \
    "./**/*.exe" "./**/*.dll"
```

#### Example: Docker Container Shell

The following example will
- use Environment Variables to setup the configuration
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually sign files, e.g.:  
    `aas-codesign.sh "./**/*.exe" "./**/*.dll"`  
    `aas-codesign.sh myapp.exe mylib.dll`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -e AZURE_TENANT_ID="MY_AZURE_TENANT_ID" \
    -e AZURE_CLIENT_ID="MY_AZURE_CLIENT_ID" \
    -e AZURE_CLIENT_SECRET="MY_AZURE_CLIENT_SECRET" \
    -e ACS_ENDPOINT=https://weu.codesigning.azure.net \
    -e ACS_ACCOUNT_NAME="ACS Code Signing Account Name" \
    -e ACS_CERTIFICATE_PROFILE_NAME="ACS Certificate Profile Name" \
    -v /local/path/to/build-folder:/data \
    jotools/codesign
```

The following example will
- use the locally stored configuration files `acs.json` and `azure.json`
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually sign files, e.g.:  
    `aas-codesign.sh "./**/*.exe" "./**/*.dll"`  
    `aas-codesign.sh myapp.exe mylib.dll`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -v /local/path/to/acs.json:/etc/aas-codesign/acs.json \
    -v /local/path/to/azure.json:/etc/aas-codesign/azure.json \
    -v /local/path/to/build-folder:/data \
    jotools/codesign
```
</details>

<details>

<summary>Code Signing using certificate `.pfx`</summary>

### Code Signing using `pfx-codesign.sh`

The included Shell Script `pfx-codesign.sh` is a helper script which will
- pick up the configuration from Environment Variables or the mounted `.json` file
- perform the Windows Code Signing with [jsign](https://github.com/ebourg/jsign)

#### Example: Docker Run - CodeSign

The following example will
- run the Docker Image [jotools/codesign](https://hub.docker.com/r/jotools/codesign)
- use configuration from `.json` file stored on the host machine
- use codesign certificate `.pfx` stored on the host machine
- mount a folder on the host machine into `/data`
- use entry point `pfx-codesign.sh`
- codesign all `.exe`'s and `.dll`'s in `/data` *(recursively)*

```
docker run \
    --rm \
    -v /local/path/to/pfx.json:/etc/pfx-codesign/pfx.json \
    -v /local/path/to/my-certificate.pfx:/etc/pfx-codesign/certificate.pfx \
    -v /local/path/to/build-folder:/data \
    -w /data \
    --entrypoint pfx-codesign.sh \
    jotools/codesign \
    "./**/*.exe" "./**/*.dll"
```

#### Example: Docker Container Shell

The following example will
- use the locally stored configuration file `pfx.json`
- use codesign certificate `.pfx` stored on the host machine
- mount a folder on the host machine into `/data`
- run the Docker Container interactively *(removing it after)*
  - use entry point `sh`
  - you then can manually sign files, e.g.:  
    `pfx-codesign.sh "./**/*.exe" "./**/*.dll"`  
    `pfx-codesign.sh myapp.exe mylib.dll`

```
docker run \
    --rm \
    -it \
    --entrypoint sh \
    -v /local/path/to/pfx.json:/etc/pfx-codesign/pfx.json \
    -v /local/path/to/my-certificate.pfx:/etc/pfx-codesign/certificate.pfx \
    -v /local/path/to/build-folder:/data \
    jotools/codesign
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
