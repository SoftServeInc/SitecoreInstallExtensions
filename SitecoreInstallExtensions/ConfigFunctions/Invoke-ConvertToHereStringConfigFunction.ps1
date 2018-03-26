#
# Invoke-ConvertToHereStringConfigFunction.ps1
#

function Invoke-ConvertToHereStringConfigFunction {
<#
.SYNOPSIS
	Converts a text lines to a here-string.

.DESCRIPTION
	A here-string is a single-quoted or double-quoted string in which quotation marks are interpreted literally.
	A here-string can span multiple lines. All the lines in a here-string are interpreted as strings even though 
	they are not enclosed in quotation marks. 

.EXAMPLE
	Json example configuration for Sitecore Install Framework:

	"Variables": {
		"ContainedQuery": "[converttoherestring('sp_configure #contained database authentication#, 1;', 'GO', 'RECONFIGURE;', 'GO')]"
	}

.EXAMPLE
	"sp_configure 'contained database authentication', 1;", "GO", "RECONFIGURE ;", "GO" | Invoke-ConvertToHereStringConfigFunction 

.EXAMPLE


.NOTE
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_quoting_rules

#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(ValueFromRemainingArguments=$true)]
        [psobject[]]$Values = @()
    )

	begin {$temp_h_string = '@"' + "`n"}

	process 
	{
		Foreach ($value in $Values) {
			$temp_h_string += $value + "`n"
		}
	}
	end 
	{
		$temp_h_string += '"@'
		iex $temp_h_string
	}
}

Export-ModuleMember Invoke-ConvertToHereStringConfigFunction
Register-SitecoreInstallExtension -Command Invoke-ConvertToHereStringConfigFunction -As ConvertToHereString -Type ConfigFunction

