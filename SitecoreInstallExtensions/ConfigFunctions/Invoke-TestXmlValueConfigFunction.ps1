#
# Invoke_TestXmlValueConfigFunction.ps1
#
function Invoke-TestXmlValueConfigFunction
{
	<#
		.SYNOPSIS
			Checks if passed node has an expected value

		.EXAMPLE
			This sample command:
			
			Invoke-TestXmlValueConfigFunction -XmlPath $webConfigPath -XPath "//appSettings/add[@key='search:define']" -ExpectedValue "Solr"

	#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string] $XmlPath,
    [Parameter(Mandatory=$true)]
    [string] $XPath,
    [Parameter(Mandatory=$true)]
    [string] $ExpectedValue
    )

    Write-Verbose "Checking node $XPath in file $XmlPath"
    [xml]$XmlDocument = Get-Content -Path $XmlPath

    $node = $XmlDocument.SelectSingleNode($XPath)

    if( $null -eq $node  )
    {
        Write-Error "Node $XPath not exists in file $XmlPath"
    }
    else
    {
        return $node.Value -match $ExpectedValue 
    }
}

Export-ModuleMember Invoke-TestXmlValueConfigFunction
Register-SitecoreInstallExtension -Command Invoke-TestXmlValueConfigFunction -As TestXmlValue -Type ConfigFunction


