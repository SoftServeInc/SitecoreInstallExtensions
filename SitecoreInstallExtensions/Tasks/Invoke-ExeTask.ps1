#
# Invoke-ExeTask.ps1
#
Function Invoke-ExeTask {
<#
.SYNOPSIS
	Executes executable file without window and waits when the process ends.

.DESCRIPTION
	The Invoke-ExeTask is registered as Exe type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"InstallVC2015Redistribuable": {
      "Type": "Exe",
      "Params": {
        "ExePath":  "[variable('Source.VC2015Redist')]",
        "Arguments": "/q"
      }
    }

.EXAMPLE
	Invoke-ExeTask -ExePath vc_redist.x64.exe -Arguments "/q"
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path $_ })]
		[string]$ExePath,
		[Parameter(Mandatory=$false)]
		[string]$Arguments
	)

	if($pscmdlet.ShouldProcess($ExePath, "Execute file with arguments $Arguments"))
    {
		Start-Process -FilePath $ExePath -ArgumentList $Arguments -NoNewWindow -Wait
	}
}

Export-ModuleMember Invoke-ExeTask

