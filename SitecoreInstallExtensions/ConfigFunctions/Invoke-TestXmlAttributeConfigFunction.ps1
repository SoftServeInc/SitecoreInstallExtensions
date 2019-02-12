
function Invoke-TestXmlAttributeConfigFunction
{
	<#
		.SYNOPSIS
			Checks if passed node has an attribute and the attribute has an expected value

		.EXAMPLE
			This sample command:
			
			Invoke-TestXmlAttributeConfigFunction -XmlPath $webConfigPath -XPath "//system.web/membership" -AttrName 'hashAlgorithmType' -ExpectedValue 'SHA1'
			
		.LINK
	#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string] $XmlPath,
    [Parameter(Mandatory=$true)]
    [string] $XPath,
    [Parameter(Mandatory=$true)]
    [string] $AttrName,
    [Parameter(Mandatory=$true)]
    [string] $ExpectedValue
    )

    Write-Verbose "Checking node $XPath in file $XmlPath"
    [xml]$XmlDocument = Get-Content -Path $XmlPath

    $node = $XmlDocument.SelectSingleNode($XPath)

    $attr = $Node.Attributes[$AttrName]
    if( $attr -ne $null )
    {
        if( $ExpectedValue -ne $null -and $attr.Value -ne $ExpectedValue )
        {
            return $false
        }

        return $true
    }
    else
    {
        return $false
    }
}


Export-ModuleMember Invoke-TestXmlAttributeConfigFunction
Register-SitecoreInstallExtension -Command Invoke-TestXmlAttributeConfigFunction -As TestXmlAttribute -Type ConfigFunction


