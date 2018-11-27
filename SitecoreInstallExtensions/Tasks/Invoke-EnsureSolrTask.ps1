#
# Ensure_SolrTask.ps1
#
function Invoke-EnsureSolrTask
{
<#
.SYNOPSIS
	Extracts Solr zip archive to specified path. 

.DESCRIPTION
	The Invoke-EnsureSolrTask is registered as EnsureSolr type.
	Sets SOLR_HOME variable to 'InstallLocation\server\solr'

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"InstallSolr": {
      "Type": "EnsureSolr",
      "Params": {
        "SolrPackage": "[variable('Source.Solr')]",
        "InstallLocation": "[variable('SolrInstallFolder')]"
      }
    }
#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# SolrPackage path to Solr zip archive
        [Parameter(Mandatory=$true)]
        $SolrPackage,

        # Path where you want to install Solr
        [Parameter(Mandatory=$true)]
        $InstallLocation
	)

	$solrHome = Join-Path -Path $InstallLocation -ChildPath "\bin\solr.in.cmd"

	if($pscmdlet.ShouldProcess($solrHome, "Verify if SOLR is installed"))
    {
		if( $solrHome -ne $null -and (Test-Path -Path $solrHome))
		{
			Write-Verbose "Solr already installed in $solrHome"
			return	
		}

		if( -not (Test-Path $InstallLocation) )
		{
			md $InstallLocation
		}

	
		Expand-Archive -Path $SolrPackage -DestinationPath $InstallLocation -Force
		
		# Move expanded content up one level
        $cleanupPath = Join-Path $InstallLocation ([IO.Path]::GetFileNameWithoutExtension($SolrPackage))
        Copy-Item -Path "$cleanUpPath\*" -Destination $InstallLocation -Recurse -Force
        Remove-Item $cleanupPath -Recurse -Force
		
		Write-Verbose "Solr installed $InstallLocation"
	}
}



function Install-SolrAsService
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$false)]
        $SolrRoot,
        [Parameter(Mandatory=$false)]
        $SolrPort,
		[Parameter(Mandatory=$false)]
        $ServiceName
	)

	if($pscmdlet.ShouldProcess("PSSolrService", "Verify if Solr as a service is installed"))
    {
		#region Check if PSSolrService is already installed
		$service = Get-Service | Where-Object {$_.name -eq $ServiceName} 
  
		if( $service -ne $null -and $service.Status -eq 'Running' )
		{
			Write-Warning -Message "$ServiceName is installed and running"
			return
		}
		#endregion
	}

	if($pscmdlet.ShouldProcess($SolrRoot, "Install SOLR as a $ServiceName on port $SolrPort"))
    {
		$command1= $PSScriptRoot+"\PSSolrService.ps1" 
		&$command1 -Setup -ServiceName $ServiceName -SolrPort $SolrPort -SolrRoot $SolrRoot -Verbose
		
        Start-Service -Name $ServiceName
	}
}

function Remove-SolrService
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$false)]
        $ServiceName
	)

	if($pscmdlet.ShouldProcess($ServiceName, "Verify if Solr as a service is installed"))
    {
		#region Check if PSSolrService is already installed
		$service = Get-Service | Where-Object {$_.name -eq $ServiceName} 
  
		if( $service -ne $null -and $service.Status -eq 'Running' )
		{
            Stop-Service -Name $ServiceName -Force

			$msg = sc.exe delete $ServiceName
            if ($LastExitCode) 
            {
                Write-Error "Failed to remove the service ${ServiceName}: $msg"
            } 
            else 
            {
                Write-Information -Message "Delete $ServiceName - $msg" -Tag "RemoveSolrService"

            }

            #Split-Path (Get-Process -Name solr2 -FileVersionInfo).FileName -Parent
		}
		#endregion
	}
}

Export-ModuleMember Invoke-EnsureSolrTask
Export-ModuleMember Install-SolrAsService
Export-ModuleMember Remove-SolrService

