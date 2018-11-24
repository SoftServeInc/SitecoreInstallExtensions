#
# Ensure that a service exists to run the specified version of Solr
#
function Invoke-EnsureSolrServiceTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$solrName,
        [parameter(Mandatory=$true)]
        [string]$installFolder,
        [parameter(Mandatory=$true)]
        [string]$nssmVersion,
        [parameter(Mandatory=$true)]
        [string]$solrRoot,
        [parameter(Mandatory=$true)]
        [string]$solrPort
    )

    PROCESS
    {
        $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        if(!($svc))
        {
            Write-Information -Message "$solrName" -Tag "Installing Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Install Solr service using NSSM"))
            {
                &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
            }

            $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Information -Message "$solrName" -Tag "Solr service already installed - skipping"
        }

        if($svc.Status -ne "Running")
        {
            Write-Information -Message "$solrName" -Tag "Starting Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Starting Solr service"))
            {
                Start-Service "$solrName"
            }
        }
        else
        {
            Write-Information -Message "$solrName" -Tag "Solr service already started - skipping"
        }
    }
}


Export-ModuleMember Invoke-EnsureSolrServiceTask
Register-SitecoreInstallExtension -Command Invoke-EnsureSolrServiceTask -As EnsureSolrService -Type Task

