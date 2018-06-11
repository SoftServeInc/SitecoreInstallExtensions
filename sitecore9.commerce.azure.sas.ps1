#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module Azure
#requires -module AzureRm.Profile
#requires -module AzureRm.Storage
#requires -module AzureRm.KeyVault
#requires -module SitecoreInstallFramework
#requires -module SitecoreInstallExtensions
#requires -module SitecoreInstallAzure

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

If(![Environment]::Is64BitProcess) 
{
    Write-Host "Please run 64-bit PowerShell" -foregroundcolor "yellow"
    return
}

#define parameters 
$LocalStorage = "$PSScriptRoot\Storage"
$GitHubRoot = "http://bit.ly/six-raw/Configuration/"

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

$AzureStorageUrl = ""
$AzureStorageToken = ""

# Do not display progress (performance improvement)
$global:ProgressPreference = 'silentlyContinue'

#region "Download Artifacts"
Invoke-WebRequest -Uri "$GitHubRoot/xcommerce9.azure.sas.json" -OutFile "$PSScriptRoot\xcommerce9.azure.json"
$downloadPrerequisites =@{
    Path = "$PSScriptRoot\xcommerce9.azure.json"   
    Destination = "$LocalStorage"
    Url = "$AzureStorageUrl"
    Token = "$AzureStorageToken"
}

try
{
	if( $steps.IsNotExecuted("downloadSitecorePrerequisites") )
	{
		Install-SitecoreConfiguration @downloadPrerequisites
		$steps.Executed("downloadSitecorePrerequisites")
	}
}
catch
{
	throw
}
#endregion

#region "Install Prerequisites"
Invoke-WebRequest -Uri "$GitHubRoot/xcommerce9.prerequisites.json" -OutFile "$PSScriptRoot\xcommerce9.prerequisites.json"

$installPrerequisites = @{    
    Path = "$PSScriptRoot\xcommerce9.prerequisites.json" 
	LocalStorage = $LocalStorage
}

try
{
	if( $steps.IsNotExecuted("installPrerequisites") )
	{
		Install-SitecoreConfiguration @installPrerequisites
		$steps.Executed("installPrerequisites")
	}
}
catch
{
	throw
}
#endregion