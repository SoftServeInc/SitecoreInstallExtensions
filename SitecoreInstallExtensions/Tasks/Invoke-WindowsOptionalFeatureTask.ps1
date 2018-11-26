#
# Invoke_WindowsOptionalFeatureTask.ps1
#
#
# Invoke-WindowsOptionalFeatureTask.ps1
#
Function Invoke-WindowsOptionalFeatureTask {
<#
.SYNOPSIS
	Installs one or more roles, role services, or features on the workstation  

.DESCRIPTION
	The Invoke-WindowsOptionalFeatureTask is registered as WindowsOptionalFeature type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"InstallRequiredFeatures": {
      "Type": "WindowsOptionalFeature",
      "Params": {
        "FeaturesToInstall":  [
			"IIS-ASPNET45",
			"IIS-WebServer"
		  ]
      }
    }
)

.EXAMPLE
	$windowsFeatures = @('IIS-ASPNET45' )
	Invoke-WindowsOptionalFeatureTask -FeaturesToInstall $windowsFeatures

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter()]
		[string[]]$FeaturesToInstall
	)

	if( ($FeaturesToInstall -ne $null) -and ($FeaturesToInstall.Count -gt 0) )
	{
		Write-Verbose "Install windows features from array $FeaturesToInstall"
		Enable-WindowsOptionalFeature -Online -FeatureName $FeaturesToInstall
	}
}

Export-ModuleMember Invoke-WindowsOptionalFeatureTask
Register-SitecoreInstallExtension -Command Invoke-WindowsOptionalFeatureTask -As WindowsOptionalFeature -Type Task


