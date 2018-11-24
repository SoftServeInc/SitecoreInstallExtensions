
function Invoke-GetPhysicalPathConfigFunction
{
<#
.SYNOPSIS
	Gets physical path to the web site.

.DESCRIPTION
   The 'Invoke-GetPhysicalPathConfigFunction' function is registered as webSitePath

.EXAMPLE
	PS:>Invoke-GetPhysicalPathConfigFunction -SiteName "sc90.local"

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
        [string]$SiteName
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand
    Write-Verbose -Message "Get website with name $SiteName"
    
    $webSite = Get-WebSite -Name $SiteName

    if( $webSite -ne $null )
    {
        return [System.Environment]::ExpandEnvironmentVariables($webSite.physicalPath) 
    }
    else
    {
        Write-Error "WebSite with name $SiteName not exists"
    }

}

Export-ModuleMember Invoke-GetPhysicalPathConfigFunction
Register-SitecoreInstallExtension -Command Invoke-GetPhysicalPathConfigFunction -As webSitePath -Type ConfigFunction



