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
Invoke-WebRequest -Uri "$GitHubRoot/sitecore9-azure.json" -OutFile "$PSScriptRoot\sitecore9-azure.json"
$downloadSitecorePrerequisites =@{
    Path = "$PSScriptRoot\sitecore9-azure.json"   
    LocalStorage = "$LocalStorage"
    SubscriptionName = ""
    ResourceGroupName = ""
    StorageName = ""
}
Install-SitecoreConfiguration @downloadSitecorePrerequisites -Verbose
#endregion

#region "Install Prerequisites"
Invoke-WebRequest -Uri "$GitHubRoot/sitecore9-server-prerequisites.json" -OutFile "$PSScriptRoot\sitecore9-server-prerequisites.json"

$serverParams = @{    
    Path = "$PSScriptRoot\sitecore9-server-prerequisites.json" 
    LocalStorage = "$LocalStorage"
} 
Install-SitecoreConfiguration @serverParams -Verbose
#endregion
 
#region "Install Solr with SSL"
Invoke-WebRequest -Uri "$GitHubRoot/Solr.json" -OutFile "$PSScriptRoot\Solr.json"
$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$LocalStorage"
    
	CertPassword = "secret"
    CertStoreLocation = "Cert:\LocalMachine\My"
    CertificateName = $SolrHost
    
    Property = "Subject"
    Value = "CN=$SolrHost"
  
    UseLocalFiles = $true
}

Install-SitecoreConfiguration @installSolr -Verbose
#endregion

#region "Step-CreateCert"

#install client certificate for xconnect 
$certParams = @{    
    Path = "$LocalStorage\xconnect-createcert.json" 
    CertificateName = "$prefix.xconnect_client" 
} 
Install-SitecoreConfiguration @certParams -Verbose 

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
 Install-SitecoreConfiguration @solrParams -Verbose 
 #endregion 

#region "Step-XConnect"
#deploy xconnect instance 
$xconnectParams = @{   
	Path = "$LocalStorage\xconnect-xp0.json" 
	Package = "$LocalStorage\Sitecore 9.0.1 rev. 171219 (OnPrem)_xp0xconnect.scwdp.zip"   
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
Install-SitecoreConfiguration @xconnectParams -Verbose 
#endregion

#region "Step-Solr-Sitecore"
#install solr cores for sitecore 
$solrParams = @{  
   Path = "$LocalStorage\sitecore-solr.json" 
   SolrUrl = $SolrUrl  
   SolrRoot = $SolrRoot  
   SolrService = $SolrService   
   CorePrefix = $prefix 
} 
Install-SitecoreConfiguration @solrParams -Verbose 
#endregion

#region "Step-Sitecore"
#install sitecore instance 

$sitecoreParams = @{  
	Path = "$LocalStorage\sitecore-XP0.json"   
	Package = "$LocalStorage\Sitecore 9.0.1 rev. 171219 (OnPrem)_single.scwdp.zip" 
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
Install-SitecoreConfiguration @sitecoreParams -Verbose 
#endregion

Start-Process "$SolrUrl"
Start-Process "http://$sitecoreSiteName"
Start-Process "https://$XConnectCollectionService"
	
	

