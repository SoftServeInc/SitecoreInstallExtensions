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

	$solrHome = [environment]::GetEnvironmentVariable("SOLR_HOME",[EnvironmentVariableTarget]::Machine)

	if($pscmdlet.ShouldProcess($solrHome, "Verify if SOLR is installed"))
    {
		if( $solrHome -ne $null )
		{
			Write-Verbose "Solr already installed SOLR_HOME is set to $solrHome"
			return	
		}

		if( -not (Test-Path $InstallLocation) )
		{
			md $InstallLocation
		}

	
		Expand-Archive -Path $SolrPackage -DestinationPath $InstallLocation
		
		# Move expanded content up one level
        $cleanupPath = Join-Path $InstallLocation ([IO.Path]::GetFileNameWithoutExtension($SolrPackage))
        Move-Item -Path "$cleanUpPath\*" -Destination $InstallLocation
        Remove-Item $cleanupPath
		
		if( $InstallLocation -ne $null )
		{
			$solrHome = Join-Path -Path $InstallLocation -ChildPath "\server\solr"
 
			[environment]::SetEnvironmentVariable("SOLR_HOME",$solrHome,[EnvironmentVariableTarget]::Machine) 
			Write-Verbose "Set SOLR_HOME variable to $solrHome"

		}
	}
}



function Install-SolrAsService
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# Solr Port
        [Parameter(Mandatory=$false)]
        $Port,

        # Solr Memory
        [Parameter(Mandatory=$false)]
        $Memory
	)

	if($pscmdlet.ShouldProcess("PSSolrService", "Verify if Solr as a service is installed"))
    {
		#region Check if PSSolrService is already installed
		$service = Get-Service | Where-Object {$_.name -eq "PSSolrService"} 
  
		if( $service -ne $null -and $service.Status -eq 'Running' )
		{
			Write-Warning -Message "PSSolrService is installed and running"
			return
		}
		#endregion
	}

	if($pscmdlet.ShouldProcess("PSSolrService.ps1", "Install SOLR as a Service"))
    {
		$command1= $PSScriptRoot+"\PSSolrService.ps1" 
		&$command1 -Setup -Verbose
		&$command1 -Start -Verbose	
	}
}

function Remove-SolrService
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# Solr Port
        [Parameter(Mandatory=$false)]
        $Port
	)

	if($pscmdlet.ShouldProcess("PSSolrService", "Verify if Solr as a service is installed"))
    {
		#region Check if PSSolrService is already installed
		$service = Get-Service | Where-Object {$_.name -eq "PSSolrService"} 
  
		if( $service -ne $null -and $service.Status -eq 'Running' )
		{
			$command1= $PSScriptRoot+"\PSSolrService.ps1" 
			&$command1 -Stop -Verbose
			&$command1 -Remove -Verbose	
		}
		#endregion
	}
}

Export-ModuleMember Invoke-EnsureSolrTask
Export-ModuleMember Install-SolrAsService
Export-ModuleMember Remove-SolrService
