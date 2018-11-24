#
# Invoke_EnsureSSLCertificateTask.ps1
#

function Invoke-EnsureSSLCertificateTask
{
<#
.SYNOPSIS
	Ensure that a trusted SSL Certificate exists for the Solr host name, and export it for Solr to use

.DESCRIPTION
	The Invoke-EnsureSSLCertificateTask is registered as EnsureSSLCertificate type. 

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"Ensure trusted SSL certificate exists (if required)": {
            "Type": "EnsureSSLCertificate",
            "Params": {
                "solrSSL":             "[parameter('SolrUseSSL')]",
                "solrName":             "[variable('SolrName')]",
                "solrHost":             "[parameter('SolrHost')]",
                "certificateStore":  "[variable('CertStoreFile')]"
            }
        },

.EXAMPLE

.NOTE
	Source: https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8

#>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [bool]$solrSSL,
        [parameter(Mandatory=$true)]
        [string]$solrName,
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$certificateStore
    )

    PROCESS
    {
        if($solrSSL)
        {
            # Generate SSL cert
            $existingCert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrName"
            if(!($existingCert))
            {
                Write-Information -Message "$solrHost" -Tag "Creating and trusting an new SSL Cert"

                if($pscmdlet.ShouldProcess("$solrHost", "Generate new trusted SSL certificate"))
                {
                    # Generate a cert
                    # https://docs.microsoft.com/en-us/powershell/module/pkiclient/new-selfsignedcertificate?view=win10-ps
                    $cert = New-SelfSignedCertificate -FriendlyName "$solrName" -DnsName "$solrHost" -CertStoreLocation "cert:\LocalMachine" -NotAfter (Get-Date).AddYears(10)

                    # Trust the cert
                    # https://stackoverflow.com/questions/8815145/how-to-trust-a-certificate-in-windows-powershell
                    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
                    $store.Open("ReadWrite")
                    $store.Add($cert)
                    $store.Close()

                    # remove the untrusted copy of the cert
                    $cert | Remove-Item
                }
            }
            else
            {
                Write-Information -Message "$solrHost" -Tag "Trusted SSL certificate already exists - skipping"
            }

            # export the cert to pfx using solr's default password
            if(!(Test-Path -Path $certificateStore))
            {
                Write-Information -Message "$certificateStore" -Tag "Exporting certificate to disk"

                $cert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrName"
    
                $certPwd = ConvertTo-SecureString -String "secret" -Force -AsPlainText

                if($pscmdlet.ShouldProcess("$certificateStore", "Export certificate to disk"))
                {
                    $cert | Export-PfxCertificate -FilePath $certificateStore -Password $certpwd | Out-Null
                }
            }
            else
            {
                Write-Information -Message "$certificateStore" -Tag "Certificate file already exported - skipping"
            }
        }
    }
}

Export-ModuleMember Invoke-EnsureSSLCertificateTask
Register-SitecoreInstallExtension -Command Invoke-EnsureSSLCertificateTask -As EnsureSSLCertificate -Type Task

