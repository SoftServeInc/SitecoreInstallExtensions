#
# Invoke-ConfigureSolrTask.ps1
#
function Invoke-ConfigureSolrTask
{
<#
.SYNOPSIS
	Process the configuration changes necessary for Solr to run

.DESCRIPTION
	The Invoke-ConfigureSolrTask is registered as ConfigureSolr type. 

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"Rewrite Solr config file": {
            "Type": "ConfigureSolr",
            "Params": {
                "solrSSL":           "[parameter('SolrUseSSL')]",
                "solrHost":          "[parameter('SolrHost')]",
                "solrRoot":          "[variable('SolrInstallFolder')]",
                "certificateStore":  "[variable('CertStoreFile')]"
            }
        },

.EXAMPLE

.NOTE
	Source: https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8
	Modified by: @RobsonAutomator
#>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [bool]$solrSSL,
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$solrRoot,
		[parameter(Mandatory=$true)]
        [string]$certificateStore,
		
        [string]$solrPort = "8983",
        
        [string]$solrMemory = "512m"

    )

    PROCESS
    {
        if($solrSSL)
        {
            Write-Information -Message "HTTPS" -Tag "Configuring Solr for HTTPS access"
            Configure-HTTPS $solrHost $solrRoot $certificateStore
        }
        else
        {
            Write-Information -Message "HTTP" -Tag "Configuring Solr for HTTP access"
            Configure-HTTP $solrHost $solrRoot
        }

		Write-Information -Message "PORT-MEMORY" -Tag "Configuring Solr $solrHost port:$solrPort ,memory:$solrMemory"
		Configure-Solr -solrRoot $solrRoot -solrHost $solrHost -solrPort $solrPort -solrMemory $solrMemory
    }
}

Export-ModuleMember Invoke-ConfigureSolrTask
Register-SitecoreInstallExtension -Command Invoke-ConfigureSolrTask -As ConfigureSolr -Type Task



