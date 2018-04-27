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

# Comment out this if you have own solr.json
$url = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/Configuration/Solr.json"
Invoke-WebRequest -Uri $url -OutFile "$PSScriptRoot\Solr.json"


#region "Install Solr with SSL"
$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$PSScriptRoot\Storage"
    CertPassword = "secret"
    CertStoreLocation = "Cert:\LocalMachine\My"
    CertificateName = "solr.local"
    
    Property = "Subject"
    Value = "CN=solr.local"
  
    UseLocalFiles = $false
}

Install-SitecoreConfiguration @installSolr -Verbose
