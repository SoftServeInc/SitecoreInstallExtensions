##############################################################################
#.SYNOPSIS
# Installs a chocolatey package
#
#.DESCRIPTION
# This will download a file from a url and install it on your machine.
#
#.EXAMPLE
#$packageName= 'bob'
#$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
#$url        = 'https://somewhere.com/file.msi'
#$url64      = 'https://somewhere.com/file-x64.msi'
#
#$packageArgs = @{
#  packageName   = $packageName
#  fileType      = 'msi'
#  url           = $url
#  url64bit      = $url64
#  silentArgs    = "/qn /norestart"
#  validExitCodes= @(0, 3010, 1641)
#  softwareName  = 'Bob*'
#  checksum      = '12345'
#  checksumType  = 'sha256'
#  checksum64    = '123356'
#  checksumType64= 'sha256'
#}
#
#Invoke-InstallChocolateyPackageTask @packageArgs
##############################################################################
Function Invoke-InstallChocolateyPackageTask {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageArgs	
    )

    if($pscmdlet.ShouldProcess("Installing Chocolatey package with arguments $PackageArgs"))
    {
        if(! (Test-Path Env:\ChocolateyInstall)) {
            Write-Warning "Chocolatey is not installed"
            Write-Warning "Installing Chocolatey."
            Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }

        Import-Module $env:PROGRAMDATA\chocolatey\helpers\chocolateyInstaller.psm1

        Install-ChocolateyPackage @$PackageArgs
    }
}

Export-ModuleMember Invoke-InstallChocolateyPackageTask