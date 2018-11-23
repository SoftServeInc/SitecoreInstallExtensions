<#
   The solr.json config perform the followin tasks:
   - if 'UseLocalFiles' is set to false then script will Download JRE and Solr 6.6.2
     (check parameters 'JREDownloadUrl' and 'JREInstaller')
   - if 'UseLocalFiles' is set to true script will look in LocalStorage for 'JREInstaller' and 'SolrPackage'
   - install JRE
   - install Solr
   - create certificates for domain 'CertificateName'
   - setup SSL for Solr
   - install Solr as a Windows Service
#>
param (
    [string]$SolrVersion = "6.6.2", 
    [string]$SolrHost = "solr.local",    
    [string]$SolrPort = "8983",
    [boolean]$SSL = $true
)


$LocalStorage = "$PSScriptRoot\Storage"
# Comment out this if you have own solr.json
$GitHubRoot = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/Configuration/"


#for Solr installation
#$SolrHost = "solr.local"
#$SolrPort = "8983"
# internally in 'solr.json', installation path is build like $SolrInstallFolder\solr-parameter('SolrVersion')
$SolrInstallFolder = "C:\solr"
$SolrService = "PSSolrService-$SolrHost"

if( -not (Test-Path "$PSScriptRoot\Solr.json" ) )
{
    Invoke-WebRequest -Uri "$GitHubRoot/Solr.json" -OutFile "$PSScriptRoot\Solr.json"
}

$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$LocalStorage"
    
    SolrVersion = $SolrVersion
	SolrHost = $SolrHost
    SolrPort = $SolrPort
    SolrUseSSL = $SSL

    SolrServiceName = $SolrService
    InstallFolder = $SolrInstallFolder

	# For SSL certificate generation
    CertPassword = "secret"
    CertStoreLocation = "Cert:\LocalMachine\My"
    CertificateName = $SolrHost
    
    # For SSL certificate export
    Property = "Subject"
    Value = "CN=$SolrHost"
	
	# if you want to download JRE and Solr check JREDownloadUrl and SolrDownloadUrl in solr.json
	# and switch to $false
    UseLocalFiles = $false
}

Install-SitecoreConfiguration @installSolr -Verbose



