
function Invoke-EnsureNSSMTask
{
<#
.SYNOPSIS
	Download and unzip the appropriate version of NSSM if it's not already in place

.DESCRIPTION
	The Invoke-EnsureNSSMTask is registered as EnsureNSSM type. 

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	 "Ensure NSSM is installed": {
            "Type": "EnsureNSSM",
            "Params": {
                "downloadFolder":    "[parameter('DownloadFolder')]",
                "nssmVersion":       "[parameter('NSSMVersion')]",
                "installFolder":     "[parameter('InstallFolder')]",
                "nssmSourcePackage": "[variable('NSSMSourcePackage')]"
            }
        },

.EXAMPLE

.NOTE
	Source: https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8
#>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$downloadFolder,

        [parameter(Mandatory=$true)]
        [string]$nssmVersion,

        [parameter(Mandatory=$true)]
        [string]$nssmSourcePackage,
        
        [parameter(Mandatory=$true)]
        [string]$installFolder
    )

    PROCESS
    {
        $targetFile = "$installFolder\nssm-$nssmVersion"
        $nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"

        Write-Information -Message "$nssmVersion" -Tag "Ensuring NSSM installed"

        DownloadAndUnzipIfRequired "NSSM" $targetFile $nssmZip $nssmSourcePackage $installFolder
    }
}

Export-ModuleMember Invoke-EnsureNSSMTask
Register-SitecoreInstallExtension -Command Invoke-EnsureNSSMTask -As EnsureNssm -Type Task


