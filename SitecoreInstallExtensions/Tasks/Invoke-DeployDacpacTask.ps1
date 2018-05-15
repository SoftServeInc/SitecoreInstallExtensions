#
# Invoke-DeployDacpacTask.ps1
#
Function Invoke-DeployDacpacTask {
<#
.SYNOPSIS
	

.DESCRIPTION
	The Invoke-ScriptBlockTask is registered as Six-DeployDacpac type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

.EXAMPLE

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(        
		[Parameter(Mandatory=$true)]
		[string]$Script,
		[Parameter(Mandatory=$false)]
		[string[]]$Arguments
	)

	
	
}

Export-ModuleMember Invoke-DeployDacpacTask
Register-SitecoreInstallExtension -Command Invoke-DeployDacpacTask -As DeployDacpac -Type Task