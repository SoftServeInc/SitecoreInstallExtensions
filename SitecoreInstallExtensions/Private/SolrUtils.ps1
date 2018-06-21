#
# Source: https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8
#
#
# Update the Solr configuration with the changes for HTTP access
#
function Configure-HTTP
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$solrHost,
        [string]$solrRoot
    )

    $solrConfig = "$solrRoot\bin\solr.in.cmd"
    if(!(Test-Path -Path "$solrConfig.old"))
    {
        if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file HTTP"))
        {
            $cfg = Get-Content $solrConfig
            Rename-Item $solrConfig "$solrConfig.old"
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
            $newCfg | Set-Content $solrConfig
        }

        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config updated for HTTP access"
    }
    else
    {
        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config already updated for HTTP access - skipping"
    }
}

#
# Update the Solr configuration with the changes for HTTPS access
#
function Configure-HTTPS
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$solrHost,
        [string]$solrRoot,
        [string]$certStore
    )

    $solrConfig = "$solrRoot\bin\solr.in.cmd"
    if(!(Test-Path -Path "$solrConfig.old"))
    {
        if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file for HTTPS"))
        {
            $cfg = Get-Content $solrConfig
            Rename-Item $solrConfig "$solrRoot\bin\solr.in.cmd.old"
            $newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStore" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=secret" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStore" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=secret" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
            $newCfg | Set-Content $solrConfig
        }

        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config updated for HTTPS access"
    }
    else
    {
        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config already updated for HTTPS access - skipping"
    }
}



function Configure-Solr
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
		[string]$solrRoot,
        [string]$solrHost = "localhost",
		[string]$solrPort = "8983",
		[string]$solrMemory = "512m"        
    )

    $solrConfig = "$solrRoot\bin\solr.in.cmd"
    if(!(Test-Path -Path "$solrConfig.config.old"))
    {
        if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file"))
        {
            $cfg = Get-Content $solrConfig
            Rename-Item $solrConfig "$solrConfig.config.old"

            $newCfg = $cfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
            
			$newCfg = $newCfg | % { $_ -replace "REM set SOLR_PORT=8983", "set SOLR_PORT=$solrPort" }
            
			$newCfg = $newCfg | % { $_ -replace "REM set SOLR_JAVA_MEM=-Xms512m -Xmx512m", "set SOLR_JAVA_MEM=-Xms$solrMemory -Xmx$solrMemory" }
            
			#REM set SOLR_JAVA_HOME=

			$newCfg | Set-Content $solrConfig
        }

        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config updated: $solrHost, $solrPort, $solrMemory"
    }
    else
    {
        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config already updated - skipping"
    }
}