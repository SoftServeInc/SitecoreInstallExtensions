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
    [string]$SolrMemory = "1024m",
    [string]$SolrService = "SolrService-$SolrHost-$SolrPort",
    [string]$SolrInstallFolder = "C:\solr", # internally in 'solr.json', installation path is build like $SolrInstallFolder\solr-parameter('SolrVersion')
    [boolean]$SSL = $true,
    [boolean]$UnInstall = $false
)

if( -not $UnInstall )
{ 
    # verify if port and host are free
    $service = Get-Service -Name $SolrService -ErrorAction SilentlyContinue
    if( $service -ne $null )
    {
        Write-Error "Service $SolrService is already running."
    }


    try
    {
        $uri = "http://$($SolrHost):$SolrPort/solr/" 
        $response = Invoke-WebRequest -Uri $uri  -ErrorAction SilentlyContinue

        Write-Error "Host and port $uri is already used."
    }
    catch{}  

}

# Do not display progress (performance improvement)
$global:ProgressPreference = 'silentlyContinue'

$LocalStorage = "$PSScriptRoot\Storage"

# Comment out this if you have own solr.json
$GitHubRoot = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/Configuration/"

if( -not (Test-Path "$PSScriptRoot\Solr.json" ) )
{
    Invoke-WebRequest -Uri "$GitHubRoot/Solr.json" -OutFile "$PSScriptRoot\Solr.json"
}
else
{
    Write-Verbose "File $PSScriptRoot\Solr.json already exists."
}


$installSolr =@{
    Path = "$PSScriptRoot\Solr.json"   
    LocalStorage = "$LocalStorage"
    
    SolrVersion = $SolrVersion
	SolrHost = $SolrHost
    SolrPort = $SolrPort
    SolrMemory = $SolrMemory
    SolrUseSSL = $SSL

    SolrServiceName = $SolrService
    InstallFolder = $SolrInstallFolder

	# For SSL certificate generation
    CertificateName = $SolrHost
    
    # For SSL certificate export
    Property = "Subject"
    Value = "CN=$SolrHost"
	
	# if you want to download JRE and Solr check JREDownloadUrl and SolrDownloadUrl in solr.json
	# and switch to $false
    UseLocalFiles = $false
    UnInstallSolr = $UnInstall
}

Install-SitecoreConfiguration @installSolr -Verbose

if( -not $UnInstall )
{
    $installSolr | ConvertTo-JSON | Set-Content -Path "$SolrInstallFolder\$SolrHost-$SolrVersion.installation.params"
}

# When you install Solr on VM in a AWS, Azure or GCP probably you have to create a firewall 
# rule to get access from remote computer.
#
# New-NetFirewallRule -LocalPort $SolrPort -DisplayName "Allow-Solr" -Direction Inbound -Protocol TCP -Action Allow

