function Invoke-RandomHexConfigFunction
{
<#
.SYNOPSIS
	Generates random hexadecimal string
.DESCRIPTION
	
.EXAMPLE
	PS:>$hex = Invoke-RandomHexConfigFunction -Length 16
	PS:>0xEB40E829C66F8B1EC1DDB93CA8CB78EE
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [string]$Length = 16
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand

	$hexString = (1..$Length | %{ '{0:X2}' -f (Get-Random -Max 256) } ) -join ''

	return "0x$hexString" 
}

Export-ModuleMember Invoke-RandomHexConfigFunction
Register-SitecoreInstallExtension -Command Invoke-RandomHexConfigFunction -As RandomHex -Type ConfigFunction