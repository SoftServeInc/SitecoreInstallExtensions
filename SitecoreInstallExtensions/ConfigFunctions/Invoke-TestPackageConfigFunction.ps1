#
# Invoke-TestPackageConfigFunction.ps1
#
function Invoke-TestPackageConfigFunction
{
<#
.SYNOPSIS
	Test if the software package has been installed.
.DESCRIPTION
	
.EXAMPLE
	PS:>$isInstalled = Invoke-TestPackageConfigFunction -Name 'Sitecore'
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [string]$Name
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand

	return $null -eq (Get-Package -Name $Name -ErrorAction SilentlyContinue)
}

Export-ModuleMember Invoke-TestPackageConfigFunction
Register-SitecoreInstallExtension -Command Invoke-TestPackageConfigFunction -As TestPackage -Type ConfigFunction

