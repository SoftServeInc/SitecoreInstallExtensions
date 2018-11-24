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

	"DeployDacpac": {
      "Type": "Six-DeployDacpac",
      "Params": {
        "DatabaseName": "Sitecore.DataExchange.Staging",
        "DacpacPath":  "C:\\inetpub\\wwwroot\\sc9u1.local\\App_Data\\packages\\Sitecore.DataExchange.Staging.dacpac",
		"ConnectionString" : "Data Source=${env:ComputerName};Integrated Security=True;Pooling=False"
      }
    }


.EXAMPLE

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(        
		[Parameter(Mandatory=$true)]
		[string]$DatabaseName,
		[Parameter(Mandatory=$true)]
		[string]$DacpacPath,
		[Parameter(Mandatory=$true)]
		[string]$ConnectionString,
		[string]$DacDllPath
	)

	if( $DacDllPath -eq $null -or $DacDllPath -eq '') 
	{
		$dll = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\*\Dac" -Recurse -Filter 'Microsoft.SqlServer.Dac.dll'
		$DacDllPath = $dll.FullName
	}
	
	Add-Type -Path $DacDllPath

	Write-Information -Message "$DacDllPath" -Tag "DeployDacpacTask"
	
	$dacServices = new-object Microsoft.SqlServer.Dac.DacServices $ConnectionString

	$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($DacpacPath) 

	Write-Information -Message "Deploy $DacpacPath as $DatabaseName to $ConnectionString" -Tag "DeployDacpacTask"

	$dacServices.Deploy($dp, $DatabaseName, $true)
}

Export-ModuleMember Invoke-DeployDacpacTask
Register-SitecoreInstallExtension -Command Invoke-DeployDacpacTask -As Six-DeployDacpac -Type Task

