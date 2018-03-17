#
# Ensure_SolrTask.ps1
#
function UnZip-Directory {
    Param(
      [Parameter(Mandatory=$True)][string]$SourceZipFile,
      [Parameter(Mandatory=$True)][string]$DestinationDirectory,
      [Parameter()][switch]$Force
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $archive = [System.IO.Compression.ZipFile]::OpenRead($SourceZipFile)
    $targetFolder = Join-Path -Path $DestinationDirectory -ChildPath $archive.Entries[0].FullName
    $archive.Dispose();

    Write-Verbose "$SourceZipFile will be extracted to $targetFolder"
    
    if( $Force -eq $true )
    {
        Remove-Item -Path $targetFolder -Recurse -Force
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($SourceZipFile, $DestinationDirectory)

    return $targetFolder
}


function Invoke-EnsureSolrTask
{
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

		$solrRoot= UnZip-Directory -SourceZipFile $SolrPackage -DestinationDirectory $InstallLocation
		if( $solrRoot -ne $null )
		{
			$solrHome = Join-Path -Path $solrRoot -ChildPath "\server\solr"
 
			[environment]::SetEnvironmentVariable("SOLR_HOME",$solrHome,[EnvironmentVariableTarget]::Machine) 
			Write-Verbose "Set SOLR_HOME variable to $solrHome"
 
			$solrBin = Join-Path -Path $solrRoot -ChildPath "bin"
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

Export-ModuleMember Invoke-EnsureSolrTask
Export-ModuleMember Install-SolrAsService
