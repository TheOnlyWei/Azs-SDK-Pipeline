<#
    You can run this script before setting up the agent to install Azure Stack modules.
#>
[CmdletBinding(DefaultParameterSetName = 'PSGallery')]
param
(
    [Parameter(Mandatory = $true, ParameterSetName = 'Custom')]
    # String variable toggling the installation of zipped Azure Stack modules from a blob storage.
    [string] $AzsModulesDownloadUrl,

    [Parameter(Mandatory = $true, ParameterSetName = 'PSGallery')]
    [string] $AzVersion,

    [Parameter(Mandatory = $true, ParameterSetName = 'PSGallery')]
    [striong] $AzureStackVersion
)
if (!(Get-PSRepository -Name PSGallery))
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Register-PSRepository -Default -Verbose
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-Module PowerShellGet -MinimumVersion 2.2.5 -SkipPublisherCheck
}

$commonScript = [io.path]::combine($PSScriptRoot, "common.psm1")
Import-Module $global:commonScript 
Import-Module -Name PowerShellGet -MinimumVersion 2.2.5

##############################################
# Set-up local Azure Stack modules directory
##############################################
if (AzsModulesDownloadUrl)
{
    $azsModulesPath = [io.path]::combine($env:SystemDrive,"azs-modules")
    if (!(Test-Path -Path $azsModulesPath))
    {
        New-Item -Path $azsModulesPath -ItemType "directory"
    }
    if (Get-PSRepository | Where-Object {$_.Name -eq "azs-modules"})
    {
        Unregister-PSRepository -Name "azs-modules"
    }

    #$AzsModulesDownloadUrl = "https://azsdevtoolstest.blob.core.windows.net/psrepo/azs-modules.zip"
    $ZipFile = [io.path]::combine($azsModulesPath, (Split-Path -Path $AzsModulesDownloadUrl -Leaf))
    Write-Host "Downloading ${AzsModulesDownloadUrl}."
    Invoke-WebRequest -Uri $AzsModulesDownloadUrl -OutFile $ZipFile 
    Write-Host "Expanding ${ZipFile}."
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $azsModulesPath -Force -PassThru
    Write-Host "Removing ${ZipFile}."
    Remove-Item -Path $ZipFile

    ##############################################
    # Set-up Azure Stack PowerShell repository
    ##############################################
    $parameters = @{
    Name = "azs-modules"
    SourceLocation = $azsModulesPath
    PublishLocation = $azsModulesPath
    InstallationPolicy = 'Trusted'
    }

    Register-PSRepository @parameters
    Write-Host "Installing Az modules."
    Install-Module Az -Repository "azs-modules"
    Write-Host "Installing Azure Stack modules."
    Install-Module AzureStack -Repository "azs-modules"
}
else
{
    Install-Module -Name Az -Repository PSGallery -RequiredVersion $AzVersion -Force
    Install-Module -Name AzureStack -Repository PSGallery -RequiredVersion $AzureStackVersion -Force
}