#requires -RunAsAdministrator 
#requires -Version 5.1

Get-PackageProvider -Name Nuget -ForceBootstrap


Install-Module Azure -MinimumVersion 5.1.2
Install-Module AzureRM -MinimumVersion 5.1.2

#region "Register Sitecore Gallery
if( (Get-PSRepository -Name SitecoreGallery -ErrorAction SilentlyContinue) -eq $null )
{
    Write-Verbose "Configure SitecoreGallery repository"
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
}
#endregion
 
#region "SitecoreInstallFramework"
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
#endregion
