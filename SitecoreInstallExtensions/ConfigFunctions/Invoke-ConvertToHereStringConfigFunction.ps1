#
# Invoke-ConvertToHereStringConfigFunction.ps1
#

# #$containedQuery = "sp_configure 'contained database authentication', 1;", "GO", "RECONFIGURE ;", "GO" | Invoke-ConvertToHereStringConfigFunction 
<#
$commands = @(
    "sp_configure 'contained database authentication', 1;",
    "GO"
    "RECONFIGURE ;",
    "GO"
)
$containedQuery = $commands | convertto-herestring 
#>

function Invoke-ConvertToHereStringConfigFunction
{
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

