#
# Invoke_ScriptBlockTask.ps1
#

Function Invoke-ScriptBlockTask {
<#
.SYNOPSIS
	Wrapper for Powershell Invoke-Command. Allows to execute Powershell commands without writing SIF tasks

.DESCRIPTION
	The Invoke-ScriptBlockTask is registered as ScriptBlock type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"WriteMessage": {
      "Type": "ScriptBlock",
      "Params": {
        "Script": "PARAM($Message,$Tag) Write-TaskInfo -Message $Message -Tag $Tag",
        "Arguments": [ "message to display", "ScriptBlock" ]
      }
    },

.EXAMPLE
	PS:> $script = 'PARAM($Path,$Filter) Get-ChildItem -Path $Path -Filter $Filter'
	PS:> Invoke-ScriptBlockTask -Script $script -Arguments @('C:\Windows','*.log')
#>
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

Export-ModuleMember Invoke-ScriptBlockTask
Register-SitecoreInstallExtension -Command Invoke-ScriptBlockTask -As ScriptBlock -Type Task
