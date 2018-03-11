#requires -RunAsAdministrator 
#requires -Version 5.1
#requires -module SitecoreInstallFramework
#requires -module SitecoreInstallExtensions

#
# Remember you should configure scripts before run 
#
If(![Environment]::Is64BitProcess) 
{
    Write-Host "Please run 64-bit PowerShell" -foregroundcolor "yellow"
    return
}

$rootFolder =  Split-Path -Path $MyInvocation.MyCommand.Source -Parent

# Choose Sitecore WebSite to uninstall
$removeParams  = Select-WebSite

$removeParams.Add("Path", "$rootFolder\Configurations\remove-sitecore8-xp0.json" )
$removeParams."Sql.Database.Sessions" = "Sitecore8u6_Sessions"

Install-SitecoreConfiguration @removeParams -Verbose
