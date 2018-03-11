#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module Azure
#requires -module AzureRm
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


# Configure all parameters without default values
# or all parameters you want to overwrite
$downloadFromAzure =@{
    Path = "$folderRoot\Configurations\azure.json"   
    Destination = "$folderRoot\Storage" 
}

Install-SitecoreConfiguration @downloadFromAzure -Verbose 



# Configure all parameters without default values
# or all parameters you want to overwrite
$prerequisitesParams =@{
    Path = "$folderRoot\Configurations\sitecore-prerequisites.json"   
    LocalStorage = "$folderRoot\Storage"
}

Install-SitecoreConfiguration @prerequisitesParams -Verbose


# Configure all parameters without default values
# or all parameters you want to overwrite
$sitecoreParams =@{
    Path = "$folderRoot\Configurations\sitecore8-xp0.json"    
    SitecoreZip = "$folderRoot\Storage\Sitecore 8.2 rev. 171121.zip"   
    SitecoreZipFileName = "Sitecore 8.2 rev. 171121" 
    LicenseFile = "$folderRoot\Storage\license.xml"
    SqlServerName = $env:COMPUTERNAME
    SiteName = "Sitecore8u6"
    SqlDbPrefix = "Sitecore8u6"
}
Install-SitecoreConfiguration @sitecoreParams -Verbose 

# Configure all parameters without default values
# or all parameters you want to overwrite
$packagesParams =@{
    Path = "$folderRoot\Configurations\sitecore-packages.json"   
    LocalStorage = "$folderRoot\Storage"   
    SiteName = "Sitecore8u6" 
}
Install-SitecoreConfiguration @packagesParams -Verbose 



