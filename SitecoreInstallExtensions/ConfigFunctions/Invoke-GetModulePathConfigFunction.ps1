#
# Invoke-GetModulePathConfigFunction.ps1
#
function Invoke-GetModulePathConfigFunction
{
<#
.SYNOPSIS
	Returns the path to the module
.DESCRIPTION
	
.EXAMPLE
	PS:>$modulePath = Invoke-GetModulePathConfigFunction -ModuleName 'SitecoreInstallExtensions'
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [string]$ModuleName
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand

	return Split-Path (Get-Module -ListAvailable $ModuleName*).path -Parent
}

Export-ModuleMember Invoke-GetModulePathConfigFunction
Register-SitecoreInstallExtension -Command Invoke-GetModulePathConfigFunction -As GetModulePath -Type ConfigFunction



