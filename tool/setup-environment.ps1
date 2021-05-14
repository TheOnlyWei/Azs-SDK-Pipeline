# This script installs tools required for the Azure Stack SDK tests.

Import-Module $PSScriptRoot\..\common.psm1

switch ($env:PROCESSOR_ARCHITECTURE) 
{
    "AMD64" { $architecture = "x64" }
    "x86" { $architecture = "x86" }
    default { throw "PowerShell package for OS architecture '$_' is not supported." }
}

$logFolder = $([io.path]::combine($env:HOMEPATH, "azurestack-sdk", "install"))
If (-not (Test-Path -Path $logFolder))
{
    New-Item $logFolder -Type Directory -ErrorAction Stop
}

####################
# INSTALL GIT CLI
####################
# Git CLI is used for Go language tests.
# Git CLI also installs OpenSSL, which is required for Python and JavaScript AZSDKTOOLSCTQ and can be found here: C:\Program Files\Git\usr\bin\openssl.exe
$architectureNumber = $architecture.Substring(1,2)
$gitCLIVersion = "2.31.1"
$gitCLIDownloadURL = "https://github.com/git-for-windows/git/releases/download/v${gitCLIVersion}.windows.1/Git-${gitCLIVersion}-${architectureNumber}-bit.exe"
$gitInstallLogFilePath = Join-Path -Path $logFolder -ChildPath "gitInstall.log"
Install-SoftwareFromURL -DownloadURL $gitCLIDownloadURL `
    -RegistryDisplayNameLike "git*" `
    -InstallLogFilePath $gitInstallLogFilePath

####################
# INSTALL PSCORE
####################
# PowerShell Core is required for the PowerShellCore tests.
$psCoreVersion = "7.1.3"
$psCoreDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v${psCoreVersion}/PowerShell-${psCoreVersion}-win-${architecture}.msi"
$psCoreInstallLogFilePath = Join-Path -Path $logFolder -ChildPath "pscoreInstall.log"
Install-SoftwareFromURL -DownloadURL $psCoreDownloadURL `
    -RegistryDisplayNameLike "Powershell 7*" `
    -InstallLogFilePath $psCoreInstallLogFilePath

####################
# INSTALL NODEJS
####################
# Install NodeJS
$nodeJSVersion = "v14.17.0"
$nodeJSDownloadURL = "https://nodejs.org/dist/${nodeJSVersion}/node-${nodeJSVersion}-${architecture}.msi"
$nodeJSInstallLogFilePath = Join-Path -Path $logFolder -ChildPath "nodejsInstall.log"
Install-SoftwareFromURL -DownloadURL $nodeJSDownloadURL `
    -RegistryDisplayNameLike "Node.js" `
    -InstallLogFilePath $nodeJSInstallLogFilePath

# Set up Azure Stack local certificate for NodeJS.
$certFolder = [System.IO.Path]::Combine($env:HOMEPATH, "certs")
if (!(Test-Path -Path $certFolder))
{
    New-Item -ItemType "directory" -Path $certFolder
}

New-NodeJSEnvPem -PemFolder $certFolder -CertLocation "Cert:\LocalMachine\root" -Certname "Baltimore CyberTrust Root, OU=CyberTrust, O=Baltimore, C=IE"

################################
# SET UP ENVIRONMENT VARIABLES
################################
$bellevueSpDetails = $env:BELLEVUE_AAD_SP_SECRET | ConvertFrom-Json
[System.Environment]::SetEnvironmentVariable('AZURE_TENANT_ID', $bellevueSpDetails.tenantId, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_ID', $bellevueSpDetails.clientId, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_SECRET', $bellevueSpDetails.clientSecret, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_OBJECT_ID', $bellevueSpDetails.objectId, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SUBSCRIPTION_ID', $bellevueSpDetails.subscriptionId, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_ARM_ENDPOINT', $bellevueSpDetails.resourceManagerEndpointUrl, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_LOCATION', $bellevueSpDetails.location, [System.EnvironmentVariableTarget]::Machine)
Remove-Variable -Name "bellevueSpDetails"