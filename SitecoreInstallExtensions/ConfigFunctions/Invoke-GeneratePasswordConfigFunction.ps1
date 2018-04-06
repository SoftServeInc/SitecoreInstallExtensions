function Invoke-GeneratePasswordConfigFunction
{
<#
.SYNOPSIS

.DESCRIPTION
	
.EXAMPLE

.NOTE

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [string]$Length = 16,
        [string]$NumberOfNonAlphanumericCharacters = 4
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand
    Write-Verbose -Message "Generate password with lenght $Length and $NumberOfNonAlphanumericCharacters non alphanumeric characters "

	Add-Type -Assembly System.Web
      
    return [Web.Security.Membership]::GeneratePassword($Length,$NumberOfNonAlphanumericCharacters)
}


$length =  32
$hexString = (1..$length | %{ '{0:X2}' -f (Get-Random -Max 256) } ) -join ''

"0x$hexString" 


Export-ModuleMember Invoke-GeneratePasswordConfigFunction
Register-SitecoreInstallExtension -Command Invoke-GeneratePasswordConfigFunction -As Password -Type ConfigFunction
