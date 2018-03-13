#
# Invoke-InstallPackageTask.ps1
#

Function Invoke-InstallPackageTask {
<#
.SYNOPSIS
	This function installs Sitecore updates or packages.
	
.DESCRIPTION
	The Invoke-InstallPackageTask function installs Sitecore package (.zip) or update (.update). 
	This function requires PackageInstaller.asmx on host where package will be installed.
	The URI is build in the following way: "http://$($HostName):$($Port)/packageinstaller.asmx?WSDL"
	
	The Invoke-InstallPackageTask is registered as InstallPackage type.

.NOTE
	Package or update must be located on server in place where IIS process has access rights

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	 "InstallWFFMPackage": {
      "Type": "InstallPackage",
      "Params": {
        "HostName": "[parameter('SiteName')]",
        "PackagePath": "[joinpath(variable('Site.PackagesPath'),'Web Forms for Marketers 8.2 rev. 170807.zip')]"
      }
    }
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$HostName,
		[Parameter(Mandatory=$false)]
		[int]$Port = 80,
		[Parameter(Mandatory=$false)]
		[string]$Timeout = 1800000,
		[Parameter(ParameterSetName='PackagePath', Mandatory=$true)]
		[string]$PackagePath,
		[Parameter(ParameterSetName='UpdatePath', Mandatory=$true)]
		[string]$UpdatePath
	)

	if($pscmdlet.ShouldProcess($HostName, "Install package/update $PackagePath or $UpdatePath"))
    {
		$proxy = New-WebServiceProxy -uri "http://$($HostName):$($Port)/packageinstaller.asmx?WSDL"
		$proxy.Timeout = $Timeout

		if( -not [string]::IsNullOrEmpty($UpdatePath) )
		{
			Write-TaskInfo -Message "Install update $UpdatePath on $HostName" -Tag Info 
			$proxy.InstallUpdatePackage($UpdatePath)
		}

		if( -not [string]::IsNullOrEmpty($PackagePath)  )
		{
			Write-TaskInfo -Message "Install package $PackagePath on $HostName" -Tag Info 
			$proxy.InstallZipPackage($PackagePath)
		}
	}
}

Export-ModuleMember Invoke-InstallPackageTask
