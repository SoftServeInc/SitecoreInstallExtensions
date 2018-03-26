#
# Invoke_ScriptBlockTask.ps1
#

# Invoke-Command -ScriptBlock {Get-ChildItem}
#$script = 'PARAM($Path,$Filter) Get-ChildItem -Path $Path -Filter $Filter'
#Invoke-ScriptBlockTask -Script $script -Arguments @('C:\Windows','*.log')

Function Invoke-ScriptBlockTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(        
		[Parameter(Mandatory=$true)]
		[string]$Script,
		[Parameter(Mandatory=$false)]
		[string[]]$Arguments
	)

	$scriptBlock = [scriptblock]::Create($Script)

	Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $Arguments
}


<#
# Without argument
Invoke-Command -ScriptBlock {Get-ChildItem}
# With one argument
Invoke-Command -ScriptBlock {Get-ChildItem $args} -ArgumentList 'C:\Windows'
# With multiple arguments - Option A
Invoke-Command -ScriptBlock {Get-ChildItem $args[0] $args[1]} -ArgumentList 'C:\Windows','*.log'
# With multiple arguments - Option B
Invoke-Command -ScriptBlock {PARAM($Path,$Filter) Get-ChildItem $Path $Filter} -ArgumentList 'C:\Windows','*.log'
# You can also be explicit and specify the parameters for more clarity
#  The argumentlist items will be sent in the same order as the parameters declared in
#  the PARAM() block.
Invoke-Command -ScriptBlock {PARAM($Path,$Filter) Get-ChildItem -Path $Path -Filter $Filter} -ArgumentList 'C:\Windows','*.log'
#>

Export-ModuleMember Invoke-ScriptBlockTask
Register-SitecoreInstallExtension -Command Invoke-ScriptBlockTask -As ScriptBlock -Type Task
