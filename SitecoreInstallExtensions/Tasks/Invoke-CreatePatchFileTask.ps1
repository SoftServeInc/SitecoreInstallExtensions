#
# InvokeCreate_PatchFileTask.ps1
#
function Invoke-NewPatchFileTask
{
<#.Synopsis
	Creates a new empty patch file.
.DESCRIPTION
	Invoke-NewPatchFileTask creates a new empty XML file with the following structure
<!--The CMS-only mode configuration settings-->
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/">
  <sitecore>
    <settings />
  </sitecore>
</configuration>

.EXAMPLE
	Invoke-NewPatchFileTask -XmlPath "C:\Sitecore\App_Config\Include\Z.Custom\cmsonly.config" -Comment "The CMS-only mode configuration settings"
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
		# XmlPath - Path to the settings file that you want to create.
		[string]$XmlPath,
		# Comment - text added as a comment at the beginning of the file.
		[string]$Comment
		)

	Write-Information -Message "Create a patch file: $XmlPath" -Tag "NewPatchFileTask"

	if( (Test-Path -Path $XmlPath) )
	{
		Write-Warning "File '$XmlPath' already exist"
		return
	}

	if( -not (Test-Path -Path ([System.IO.Path]::GetDirectoryName($XmlPath)) ))
	{
		mkdir ([System.IO.Path]::GetDirectoryName($XmlPath)) | Out-Null
	}

	[System.XML.XMLDocument]$XmlDocument = New-Object System.XML.XMLDocument

	$configuration = $XmlDocument.CreateElement("configuration")
	$configuration.SetAttribute("xmlns:patch",  "http://www.sitecore.net/xmlconfig/")
	$configuration.SetAttribute("xmlns:set",  "http://www.sitecore.net/xmlconfig/set/")

	$sitecore = $XmlDocument.CreateElement("sitecore")
	$settings = $XmlDocument.CreateElement("settings")

	$XmlDocument.appendChild($configuration)
	$configuration.appendChild($sitecore)
	$sitecore.appendChild($settings)

	
	if( [String]::IsNullOrWhiteSpace($Comment) -eq $false )
	{
		$xmlComment = $XmlDocument.CreateComment($Comment);
		$XmlDocument.InsertBefore($xmlComment,$configuration)
	}

	$XmlDocument.Save($XmlPath);
}


function Invoke-AddPatchTask
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateScript ({Test-Path $_})]
		[string]$XmlPath,

		[ValidateNotNullOrEmpty()]
		[string]$XPath = "//configuration/sitecore/settings",
	
		[ValidateNotNullOrEmpty()]
		[string]$Element = "setting",

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[string]$Value,
		
		[string]$Comment
	)

	[xml]$XmlDocument = Get-Content -Path $XmlPath

	$appSettingsNode = $XmlDocument.SelectSingleNode($XPath)
 
	if($appSettingsNode -eq $null)
	{
		$(throw "Node does not exists! Invalid configuration file.")
	}

	$existingNode = $XmlDocument.SelectNodes("$XPath/$Element") | Where-Object {$_ -ne $null -and $_.Name -eq $Name}
	if( $existingNode -ne $null )
	{
		Write-Verbose "Patch for element $Element with name=$Name already exist"
		return
	}

	[System.Xml.XmlElement]$item = $XmlDocument.CreateElement($Element)
    if( $item -eq $null )
    {
        Write-Verbose "Cannot create an element $Element"
        return
    }


	$item.SetAttribute("name",  $Name)
    
    Write-Information -Message "Create patch for elemeny $Element, name $Name = $Value" -Tag "Patch"
	if( $Value -eq $null -or $Value -eq '')
	{
		$patch = $XmlDocument.CreateElement("patch","delete","http://www.sitecore.net/xmlconfig/")
		$item.AppendChild($patch)
	}
	else
	{
		$patch = $XmlDocument.CreateElement("patch","attribute","http://www.sitecore.net/xmlconfig/")
		$patch.SetAttribute("name",  "value")
		$patch.InnerText = $Value
		$item.AppendChild($patch)
	}
	
	$appSettingsNode.AppendChild($item);
	
	if( [String]::IsNullOrWhiteSpace($Comment) -eq $false )
	{
		$xmlComment = $XmlDocument.CreateComment($Comment);
		$appSettingsNode.InsertBefore($xmlComment,$item)
	}

	if ($pscmdlet.ShouldProcess($XmlPath))
	{		
		$XmlDocument.Save($XmlPath);
	}
}



Export-ModuleMember Invoke-AddPatchTask
Register-SitecoreInstallExtension -Command Invoke-AddPatchTask -As Six-AddPatch -Type Task

Export-ModuleMember Invoke-NewPatchFileTask
Register-SitecoreInstallExtension -Command Invoke-NewPatchFileTask -As Six-CreatePatchFile -Type Task



