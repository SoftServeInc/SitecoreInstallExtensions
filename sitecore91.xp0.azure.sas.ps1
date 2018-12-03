#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module Azure
#requires -module AzureRm.Profile
#requires -module AzureRm.Storage
#requires -module AzureRm.KeyVault
#requires -modules @{ ModuleName="SitecoreInstallFramework"; ModuleVersion="2.0.0" } 
#requires -module SitecoreInstallExtensions
#requires -module SitecoreInstallAzure

If(![Environment]::Is64BitProcess) 
{
    Write-Host "Please run 64-bit PowerShell" -foregroundcolor "yellow"
    return
}

#region Steps implementation
class Steps
{
   [string] $Path
   $Steps = @()

   Steps ([string] $path)
   {
	   $this.Path = $path -replace "ps1","steps.json"
       if( (Test-Path $this.Path) )
       {
           $this.Steps = (Get-Content -Path $this.Path -Raw) | ConvertFrom-Json
       }    
       else
       {
           $this.Steps = @()
	   }
   }

	# mark step as executed
	Executed([string] $stepName)
	{
        $this.Steps += $stepName

        $json = ConvertTo-Json -InputObject $this.Steps
        Set-Content -Path $this.Path -Value $json
	}

	[bool] IsNotExecuted([string] $stepName)
	{
		return -not ($this.Steps.Contains($stepName))
	}
}
#endregion

#region "Parameters" 
$LocalStorage = "$PSScriptRoot\Storage"
$GitHubRoot = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/Configuration/"

# Prefix is used for Sitecore website, xConnect website and database 
$prefix = "xp910"

$SitecoreSiteName = "$prefix.local" 
# The name of the XConnect service.
$XConnectSiteName = "$prefix.xconnect"
# The Identity Server site name.
$IdentityServerSiteName = "$prefix.identityserver"

#for Solr installation
$SolrHost = "solr.local"
$SolrPort = "8983"
# internally in 'solr.json', installation path is build like $SolrInstallFolder\solr-parameter('SolrVersion')
$SolrInstallFolder = "C:\solr"
$SolrService = "PSSolrService"

# for Solr cores configuration
$SolrRoot = "$SolrInstallFolder\solr-7.2.1"
$SolrUrl = "https://$($SolrHost):$($SolrPort)/solr"

$SqlServer = "$env:computername" #OR "SQLServerName\SQLInstanceName"
$SqlAdminUser = ""
$SqlAdminPassword= ''

$AzureStorageUrl = ""
$AzureStorageToken = ""

# Choose version for download
$SitecoreVersion = "9.1"

# The Identity Server password recovery URL, this should be the URL of the CM instance.
$PasswordRecoveryUrl = "http://$SitecoreSiteName"
# The URL of the XconnectService.
$XConnectCollectionService = "https://$XConnectSiteName"
# The URL of the Identity Authority.
$SitecoreIdentityAuthority = "https://$IdentityServerSiteName"
# The random string key used for establishing a connection with the IdentityService.
$ClientSecret = "SIF-Default"
# A pipe-separated list of instances (URIs) that are allowed to log in through Sitecore Identity.
$AllowedCorsOrigins = "http://$SitecoreSiteName"

#endregion

###################################################################################
#
#	Always read and configure parameters in section above
#
###################################################################################

# For Windows Server $Workstation must be set to $false, for Windows 8/10/Next to $true
$Workstation = !((gwmi win32_operatingsystem).caption -split " " -contains "Server")

# Do not display progress (performance improvement)
$global:ProgressPreference = 'silentlyContinue'

# initialize steps functionality
$steps = [Steps]::new($MyInvocation.MyCommand.Source)


#region "Download Artifacts"
Invoke-WebRequest -Uri "$GitHubRoot/sitecore9.azure.sas.json" -OutFile "$PSScriptRoot\sitecore9.azure.json"
$downloadSitecorePrerequisites = @{
    Path = "$PSScriptRoot\sitecore9.azure.json"   
    Destination = $LocalStorage
    StorageUrl = $AzureStorageUrl
    StorageSas = $AzureStorageToken
	SitecoreVersion = $SitecoreVersion
}

try
{
	if( ( $null -ne $AzureStorageUrl ) -and  ( $null -ne $AzureStorageToken ) )
	{
		if( $steps.IsNotExecuted("downloadSitecorePrerequisites") )
		{
			Install-SitecoreConfiguration @downloadSitecorePrerequisites
			$steps.Executed("downloadSitecorePrerequisites")
		}
	}
}
catch
{
	throw
}
#endregion



#region "Install Prerequisites"
Invoke-WebRequest -Uri "$GitHubRoot/sitecore91.prerequisites.json" -OutFile "$PSScriptRoot\sitecore91.prerequisites.json"
$prerequisites = @{    
    Path = "$PSScriptRoot\sitecore91.prerequisites.json"
    LocalStorage = $LocalStorage
    SqlServer = $SqlServer
    SqlAdminUser = $SqlAdminUser
    SqlAdminPassword = $SqlAdminPassword
} 

try
{	
	if( $steps.IsNotExecuted("installPrerequisites") )
	{
		Install-SitecoreConfiguration @prerequisites -Verbose
		$steps.Executed("installPrerequisites")
	}
}
catch
{
	throw
}
#endregion


#region "Install Solr with SSL"
Invoke-WebRequest -Uri "$GitHubRoot/solr7.json" -OutFile "$PSScriptRoot\Solr.json"

$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$LocalStorage"
    
	SolrHost = $SolrHost
    SolrPort = $SolrPort
    SolrServiceName = $SolrService
    InstallFolder = "$SolrInstallFolder"

	# For SSL certificate generation
    CertificateName = $SolrHost
 
	# if you want to download JRE and Solr check JREDownloadUrl and SolrDownloadUrl in solr.json
	# and switch to $false
    UseLocalFiles = $false
}

try
{
	if( $steps.IsNotExecuted("installSolr") )
	{ 
		Install-SitecoreConfiguration @installSolr
		$steps.Executed("installSolr")
	}
}
catch
{
	throw
}
#endregion



#region "XP0-SingleDeveloper"
$singleParams = @{    
    Path = "$LocalStorage\XP0-SingleDeveloper.json"
    SqlServer = $SqlServer
    SqlAdminUser = $SqlAdminUser
    SqlAdminPassword = $SqlAdminPassword
    SolrUrl = $SolrUrl
    SolrRoot = $SolrRoot
    SolrService = $SolrService
    Prefix = $prefix
    XConnectCertificateName = $XConnectSiteName
    IdentityServerCertificateName = $IdentityServerSiteName
    IdentityServerSiteName = $IdentityServerSiteName
    LicenseFile = "$LocalStorage\license.xml"  
    XConnectPackage = "$LocalStorage\Sitecore * (OnPrem)_xp0xconnect.scwdp.zip"
    SitecorePackage = "$LocalStorage\Sitecore * (OnPrem)_single.scwdp.zip"   
    IdentityServerPackage = "$LocalStorage\Sitecore.IdentityServer * (OnPrem)_identityserver.scwdp.zip"
    
    XConnectSiteName = $XConnectSiteName
    SitecoreSitename = $SitecoreSiteName
    PasswordRecoveryUrl = $PasswordRecoveryUrl
    SitecoreIdentityAuthority = $SitecoreIdentityAuthority
    XConnectCollectionService = $XConnectCollectionService
    ClientSecret = $ClientSecret
    AllowedCorsOrigins = $AllowedCorsOrigins
} 


try
{
	if( $steps.IsNotExecuted("singleParams") )
	{
        Push-Location $LocalStorage
		Install-SitecoreConfiguration @singleParams -Verbose
        Pop-Location
		$steps.Executed("singleParams")
	}
}
catch
{
	throw
}
#endregion 

Start-Process $SolrUrl
Start-Process "http://$sitecoreSiteName"
Start-Process "https://$XConnectCollectionService"
	

