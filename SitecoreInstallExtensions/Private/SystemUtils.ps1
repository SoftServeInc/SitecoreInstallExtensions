#
# SystemUtils.ps1
#
#
# If necessary, download a file and unzip it to the specified location
# Source: https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8
function DownloadAndUnzipIfRequired
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$toolName,
        [string]$toolFolder,
        [string]$toolZip,
        [string]$toolSourceFile,
        [string]$installRoot
    )

    if(!(Test-Path -Path $toolFolder))
    {
        if(!(Test-Path -Path $toolZip))
        {
            Write-TaskInfo -Message $toolSourceFile -Tag "Downloading $toolName"
            if($pscmdlet.ShouldProcess("$toolSourceFile", "Download source file"))
            {
                Start-BitsTransfer -Source $toolSourceFile -Destination $toolZip
            }
        }
        else
        {
            Write-TaskInfo -Message $toolZip -Tag "$toolName already downloaded"
        }

        Write-TaskInfo -Message $targetFile -Tag "Extracting $toolName"
        if($pscmdlet.ShouldProcess("$toolZip", "Extract archive file"))
        {
            Expand-Archive $toolZip -DestinationPath $installRoot -Force
        }
    }
    else
    {
        Write-TaskInfo -Message $toolFolder -Tag "$toolName folder already exists - skipping"
    }
}

function Get-ServicePath
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$serviceName
    )

	$service = Get-CimInstance -Class Win32_Service | Where-Object {$_.Name -eq $serviceName }
	if( $service -ne $null )
	{
		return $service.PathName
	}
	else
	{
		return ""
	}
}



# Some utility functions to help in the script
# Source: https://github.com/Kieranties/SIfSug/blob/master/Environment/Server-Setup.ps1
Function ModuleAbsent ($Name){
    return $null -eq (Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue)
}

Function PackageAbsent ($Name){
    return $null -eq (Get-Package -Name $Name -ErrorAction SilentlyContinue)
}

Function RepositoryAbsent ($Name) {
    return $null -eq (Get-PSRepository -Name $Name -ErrorAction SilentlyContinue)
}