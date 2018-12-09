#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module Azure
#requires -module AzureRm.Profile
#requires -module AzureRm.Storage
#requires -module AzureRm.KeyVault
#requires -modules @{ ModuleName="SitecoreInstallFramework"; ModuleVersion="1.2.1" } 
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
$prefix = "sc9u2"
$sitecoreSiteName = "$prefix.local" 

$XConnectCollectionService = "$prefix.xconnect"

#for Solr installation
$SolrHost = "solr.local"
$SolrPort = "8983"
# internally in 'solr.json', installation path is build like $SolrInstallFolder\solr-parameter('SolrVersion')
$SolrInstallFolder = "C:\solr"
$SolrService = "PSSolrService"

# for Solr cores configuration
$SolrRoot = "$SolrInstallFolder\solr-6.6.2"
$SolrUrl = "https://$($SolrHost):$($SolrPort)/solr"

$SqlServer = "$env:computername" #OR "SQLServerName\SQLInstanceName"
$SqlAdminUser = ""
# for password use '' not ""
$SqlAdminPassword= '' 

$AzureStorageUrl = ""
$AzureStorageToken = ""

# Choose version for download
$SitecoreVersion = "9.0.2"

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
	if( $steps.IsNotExecuted("downloadSitecorePrerequisites") )
	{
		Install-SitecoreConfiguration @downloadSitecorePrerequisites
		$steps.Executed("downloadSitecorePrerequisites")
	}
}
catch
{
	throw
}
#endregion

#region "Install Prerequisites"
Invoke-WebRequest -Uri "$GitHubRoot/sitecore9.prerequisites.json" -OutFile "$PSScriptRoot\sitecore9.prerequisites.json"

$prerequisites = @{    
    Path = "$PSScriptRoot\sitecore9.prerequisites.json" 
	LocalStorage = $LocalStorage
	SqlServer = $SqlServer 
	SqlAdminUser = $SqlAdminUser   
	SqlAdminPassword = $SqlAdminPassword
	
	Workstation = $Workstation
} 

try
{	
	if( $steps.IsNotExecuted("installPrerequisites") )
	{
		Install-SitecoreConfiguration @prerequisites
		$steps.Executed("installPrerequisites")
	}
}
catch
{
	throw
}
#endregion
 
#region "Install Solr with SSL"
Invoke-WebRequest -Uri "$GitHubRoot/Solr.json" -OutFile "$PSScriptRoot\Solr.json"
$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$LocalStorage"
    
	SolrHost = $SolrHost
    SolrPort = $SolrPort
    SolrServiceName = $SolrService

    # By default SOLR will be installed in "C:\solr", change install folder parameter if you want
    InstallFolder = "$SolrInstallFolder"

	# For SSL certificate generation
    CertPassword = "secret"
    CertStoreLocation = "Cert:\LocalMachine\My"
    CertificateName = $SolrHost
    Property = "Subject"
    Value = "CN=$SolrHost"
	
	# if you want to download JRE and Solr check JREDownloadUrl and SolrDownloadUrl in solr.json
	# and switch to $false
    UseLocalFiles = $true
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

#region "Step-CreateCert"

#install client certificate for xconnect 
$certParams = @{    
    Path = "$LocalStorage\xconnect-createcert.json" 
    CertificateName = "$prefix.xconnect_client" 
} 

try
{
	if( $steps.IsNotExecuted("certParams") )
	{
		Install-SitecoreConfiguration @certParams
		$steps.Executed("certParams")
	}
}
catch
{
	throw
}
#endregion 

#region "Step-Solr-XConnect"
#install solr cores for xdb
$solrParams = @{ 
	 Path = "$LocalStorage\xconnect-solr.json"  
	 SolrUrl = $SolrUrl     
	 SolrRoot = $SolrRoot  
	 SolrService = $SolrService  
	 CorePrefix = $prefix 
}
  
try
{
	if( $steps.IsNotExecuted("solrParams") )
	{
		Install-SitecoreConfiguration @solrParams
		$steps.Executed("solrParams")
	}
}
catch
{
	throw
} 
#endregion 

#region "Step-XConnect-Web"
#deploy xconnect instance 
$xconnectParams = @{   
	Path = "$LocalStorage\xconnect-xp0.json" 
	Package = "$LocalStorage\Sitecore * (OnPrem)_xp0xconnect.scwdp.zip"   
	LicenseFile = "$LocalStorage\license.xml"  
	Sitename = $XConnectCollectionService    
	XConnectCert = $certParams.CertificateName   
	SqlDbPrefix = $prefix
	SqlServer = $SqlServer
	SqlAdminUser = $SqlAdminUser  
	SqlAdminPassword = $SqlAdminPassword  
	SolrCorePrefix = $prefix  
	SolrURL = $SolrUrl  
} 
try
{
	if( $steps.IsNotExecuted("xconnectParams") )
	{
		Install-SitecoreConfiguration @xconnectParams
		$steps.Executed("xconnectParams")
	}
}
catch
{
	throw
} 
#endregion

#region "Step-Solr-Sitecore"
#install solr cores for sitecore 
$sitecoreSolrParams = @{  
   Path = "$LocalStorage\sitecore-solr.json" 
   SolrUrl = $SolrUrl  
   SolrRoot = $SolrRoot  
   SolrService = $SolrService   
   CorePrefix = $prefix 
} 
 
try
{
	if( $steps.IsNotExecuted("sitecoreSolrParams") )
	{
		Install-SitecoreConfiguration @sitecoreSolrParams
		$steps.Executed("sitecoreSolrParams")
	}
}
catch
{
	throw
}
#endregion

#region "Step-Sitecore"
#install sitecore instance 
$sitecoreParams = @{  
	Path = "$LocalStorage\sitecore-XP0.json"   
	Package = "$LocalStorage\Sitecore * (OnPrem)_single.scwdp.zip" 
    LicenseFile = "$LocalStorage\license.xml"   
	SqlDbPrefix = $prefix  
	SqlServer = $SqlServer 
	SqlAdminUser = $SqlAdminUser   
	SqlAdminPassword = $SqlAdminPassword  
	SolrCorePrefix = $prefix 
	SolrUrl = $SolrUrl   
	XConnectCert = $certParams.CertificateName   
	Sitename = $sitecoreSiteName       
	XConnectCollectionService = "https://$XConnectCollectionService"
}
try
{
	if( $steps.IsNotExecuted("sitecoreParams") )
	{
		Install-SitecoreConfiguration @sitecoreParams
		$steps.Executed("sitecoreParams")
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
	

