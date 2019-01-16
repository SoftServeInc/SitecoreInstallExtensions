#requires -RunAsAdministrator 
#requires -Version 5.1

param(
    [switch] $Azure	= $true
)

# Do not display progress (performance improvement)
$global:ProgressPreference = 'silentlyContinue'


Get-PackageProvider -Name Nuget -ForceBootstrap

#region "WebAdministration module"
# Module WebAdministration is required by Sitecore Install Framework
# This module is installed as part of Web-Server feature
if( (Get-Module -Name WebAdministration -ListAvailable) -eq $null )
{
	If ( [bool](Get-Command -Name "Install-WindowsFeature" -ErrorAction SilentlyContinue) )
	{
        Install-WindowsFeature -Name Web-Server
    }
	else 
	{
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
    }
}
#endregion

#Temporary change default installation policy
$defaultPolicy = (Get-PSRepository -Name PSGallery).InstallationPolicy
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

if( $Azure -eq $true)
{
	Install-Module Azure -MinimumVersion 5.1.2
	Install-Module AzureRM.Profile
	Install-Module AzureRM.Storage
	Install-Module AzureRM.KeyVault
}

#region "Register Sitecore Gallery
if( (Get-PSRepository -Name SitecoreGallery -ErrorAction SilentlyContinue) -eq $null )
{
    Write-Verbose "Configure SitecoreGallery repository"
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
}
#endregion
 
#region "SitecoreInstallFramework for Sitecore 9.1 and later"
if( (Get-Module -Name SitecoreInstallFramework -ListAvailable) -eq $null )
{
    #If install-module is not available check https://www.microsoft.com/en-us/download/details.aspx?id=49186
    Install-Module SitecoreInstallFramework -Scope AllUsers -Repository SitecoreGallery
}
else
{
    Write-Verbose "SIF module already installed, update then"
	Update-Module SitecoreInstallFramework -Force
}
#endregion

#region "SitecoreInstallFramework for Sitecore 9.0.x"
$sifModule = Get-Module -Name SitecoreInstallFramework -ListAvailable
if(  $sifModule -eq $null -or $sifModule.Version -ne '1.2.1'  )
{
    #If install-module is not available check https://www.microsoft.com/en-us/download/details.aspx?id=49186
    Install-Module SitecoreInstallFramework -Scope AllUsers -Repository SitecoreGallery -RequiredVersion 1.2.1 -AllowClobber
}
#endregion

#region "SitecoreFundamentals"
if( (Get-Module -Name SitecoreFundamentals -ListAvailable) -eq $null )
{
    #If install-module is not available check https://www.microsoft.com/en-us/download/details.aspx?id=49186
    Install-Module SitecoreFundamentals -Scope AllUsers -Repository SitecoreGallery
}
else
{
    Write-Verbose "SitecoreFundamentals module already installed, update then"
	Update-Module SitecoreFundamentals -Force
}
#endregion

#region "SitecoreInstallExtensions"
if( (Get-Module -Name SitecoreInstallExtensions -ListAvailable) -eq $null )
{
    #If install-module is not available check https://www.microsoft.com/en-us/download/details.aspx?id=49186
    Install-Module SitecoreInstallExtensions -Scope AllUsers -Repository PSGallery
}
else
{
    Write-Verbose "SitecoreInstallExtensions module already installed, update then"
	Update-Module SitecoreInstallExtensions -Force
}
#endregion

#region "SitecoreInstallAzure"
if( $Azure -eq $true)
{
	if( (Get-Module -Name SitecoreInstallAzure -ListAvailable) -eq $null )
	{
    	#If install-module is not available check https://www.microsoft.com/en-us/download/details.aspx?id=49186
    	Install-Module SitecoreInstallAzure -Scope AllUsers -Repository PSGallery
	}
	else
	{
    	Write-Verbose "SitecoreInstallAzure module already installed, update then"
		Update-Module SitecoreInstallAzure -Force
	}
}
#endregion

Set-PSRepository PSGallery -InstallationPolicy $defaultPolicy

Get-Module Sitecore* -ListAvailable | Format-List
