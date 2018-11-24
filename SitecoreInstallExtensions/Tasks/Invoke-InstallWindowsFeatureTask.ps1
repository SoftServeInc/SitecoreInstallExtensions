#
# Invoke-InstallWindowsFeatureTask.ps1
#
Function Invoke-InstallWindowsFeatureTask {
<#
.SYNOPSIS
	Installs one or more roles, role services, or features on the local server 

.DESCRIPTION
	The Invoke-InstallWindowsFeatureTask is registered as InstallWindowsFeature type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"InstallRequiredFeatures": {
      "Type": "InstallWindowsFeature",
      "Params": {
        "FeaturesToInstall":  [
			"Net-Framework-45-ASPNET",
			"Web-Server",
			"Web-Mgmt-Tools",
		  ]
        "XmlPath": "required-features.xml"
      }
    }
)

.EXAMPLE
	$windowsFeatures = @('Net-Framework-45-ASPNET', 'Web-Server' )
	Invoke-InstallWindowsFeatureTask -FeaturesToInstall $windowsFeatures

.NOTE
	This task requires 'servermanager' module.
	For a client-base operating system need to install https://www.microsoft.com/en-us/download/details.aspx?id=45520

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter()]
		[string[]]$FeaturesToInstall,
		[Parameter()]
		[string]$XmlPath
	)

	$installed = (Get-Module servermanager -ListAvailable -ErrorAction SilentlyContinue) -ne $null
	if( $installed -ne $true )
	{
		throw "Install-Module servermanager"
	}

	if( ($FeaturesToInstall -ne $null) -and ($FeaturesToInstall.Count -gt 0) )
	{
		Write-Verbose "Install windows features from array $FeaturesToInstall"
		Install-WindowsFeature -Name $FeaturesToInstall 
	}

	if( ($XmlPath -ne '') -and (Test-Path $XmlPath) )
	{
		Write-Verbose "Install windows features from file $XmlPath"
		Install-WindowsFeature -ConfigurationFilePath $XmlPath
	}
}

Export-ModuleMember Invoke-InstallWindowsFeatureTask
Register-SitecoreInstallExtension -Command Invoke-InstallWindowsFeatureTask -As InstallWindowsFeature -Type Task


