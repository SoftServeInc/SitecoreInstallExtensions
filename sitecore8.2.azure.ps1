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

#
# Remember you should configure scripts before run 
#
$folderRoot = Split-Path -Path $MyInvocation.MyCommand.Source -Parent

$sitecoreVersion = "8.2"
$sitecoreRevision = "160729"
$sitecoreRole = "CM"
# Prefix is used for Sitecore website, xConnect website and database 
$prefix = "sc82"
$siteName = "$prefix.local"

$MongoDbServer = ""

$AzureSubscription = ""
$AzureResourceGroup = ""
$AzureStorageName = ""

$SqlServer = "$env:computername" #OR "SQLServerName\SQLInstanceName"
$SqlAdminUser = ""
# for password use '' not ""
$SqlAdminPassword= '' 


# Configure all parameters without default values
# or all parameters you want to overwrite
$downloadFromAzure =@{
    Path = "$folderRoot\azure.json"   
    Destination = "$folderRoot\Storage"
    SitecoreVersion = $sitecoreVersion
    SitecoreRevision = $sitecoreRevision
    SitecoreRole = $sitecoreRole
    SubscriptionName = $AzureSubscription
    ResourceGroupName = $AzureResourceGroup
    StorageName = $AzureStorageName
    InstallMongoDb = $false
    InstallSolr = $false
}

Install-SitecoreConfiguration @downloadFromAzure -Verbose 

# Configure all parameters without default values
# or all parameters you want to overwrite
$prerequisitesParams =@{
    Path = "$folderRoot\sitecore-prerequisites.json"   
    LocalStorage = "$folderRoot\Storage"
    InstallMongoDb = $false
    InstallSolr = $false
}

Install-SitecoreConfiguration @prerequisitesParams -Verbose


# Configure all parameters without default values
# or all parameters you want to overwrite
$sitecoreParams =@{
    Path = "$folderRoot\sitecore8-xp0.json"    
    SitecoreZip = "$folderRoot\Storage\Sitecore $SitecoreVersion rev. $SitecoreRevision.zip"   
    SitecoreZipFileName = "Sitecore $SitecoreVersion rev. $SitecoreRevision" 
    LicenseFile = "$folderRoot\Storage\license.xml"
    SqlServerName = $SqlServer
    SqlUser = $SqlAdminUser
    SqlPassword = $SqlAdminPassword
    SiteName = $siteName
    SqlDbPrefix = $prefix
    MongoServerName = $MongoDbServer
}
Install-SitecoreConfiguration @sitecoreParams -Verbose 

# Configure all parameters without default values
# or all parameters you want to overwrite
$packagesParams =@{
    Path = "$folderRoot\sitecore-packages.json"   
    LocalStorage = "$folderRoot\Storage"   
    SiteName = $siteName
    SqlServerName = $SqlServer
    SqlUser = $SqlAdminUser
    SqlPassword = $SqlAdminPassword
    SqlDbPrefix = $prefix
}

Install-SitecoreConfiguration @packagesParams -Verbose 



