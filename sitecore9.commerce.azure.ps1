#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module Azure
#requires -module AzureRm.Profile
#requires -module AzureRm.Storage
#requires -module AzureRm.KeyVault
#requires -module SitecoreInstallFramework
#requires -module SitecoreInstallExtensions
#requires -module SitecoreInstallAzure

If(![Environment]::Is64BitProcess) 
{
    Write-Host "Please run 64-bit PowerShell" -foregroundcolor "yellow"
    return
}

#define parameters 
$LocalStorage = "$PSScriptRoot\Storage"
$GitHubRoot = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/Configuration/"

$prefix = "sc9u1"
$sitecoreSiteName = "$prefix.local" 

$XConnectCollectionService = "$prefix.xconnect"

$SolrHost = "solr.local"
$SolrUrl = "https://solr.local:8983/solr" 
$SolrRoot = "C:\solr\solr-6.6.2"
$SolrService = "PSSolrService"

$SqlServer = "$env:computername" #OR "SQLServerName\SQLInstanceName"
$SqlAdminUser = ""
$SqlAdminPassword= "" 

# Do not display progress (performance improvement)
$global:ProgressPreference = 'silentlyContinue'

#region "Download Artifacts"
Invoke-WebRequest -Uri "$GitHubRoot/sitecore9.azure.json" -OutFile "$PSScriptRoot\xcommerce9.azure.json"
$downloadPrerequisites =@{
    Path = "$PSScriptRoot\xcommerce9.azure.json"   
    Destination = "$LocalStorage"
    SubscriptionName = ""
    ResourceGroupName = ""
    StorageName = ""
}
Install-SitecoreConfiguration @downloadPrerequisites
#endregion

#region "Install Prerequisites"
Invoke-WebRequest -Uri "$GitHubRoot/xcommerce9.prerequisites.json" -OutFile "$PSScriptRoot\xcommerce9.prerequisites.json"

$installPrerequisites = @{    
    Path = "$PSScriptRoot\xcommerce9.prerequisites.json" 
	LocalStorage = $LocalStorage
}

Install-SitecoreConfiguration @installPrerequisites -Verbose
#endregion