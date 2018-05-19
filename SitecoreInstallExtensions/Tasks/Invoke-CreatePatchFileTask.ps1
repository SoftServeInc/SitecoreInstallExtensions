#
# InvokeCreate_PatchFileTask.ps1
#
<#.Synopsis
	Creates a new empty patch file.
.DESCRIPTION
	New-SettingsFile creates a new empty XML file with the following structure
<!--The CMS-only mode configuration settings-->
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/">
  <sitecore>
    <settings />
  </sitecore>
</configuration>

.EXAMPLE
	Invoke-NewPatchFileTask -XmlPath "C:\sitecore\website\App_Config\Include\Z.CmsOnlyMode\cmsonly.config" -Comment "The CMS-only mode configuration settings"
#>
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
	Invoke-NewPatchFileTask -XmlPath "C:\sitecore\website\App_Config\Include\Z.CmsOnlyMode\cmsonly.config" -Comment "The CMS-only mode configuration settings"
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
		# XmlPath - Path to the settings file that you want to create.
		[string]$XmlPath,
		# Comment - text added as a comment at the beginning of the file.
		[string]$Comment
		)

	Write-TaskInfo -Message "Create a patch file: $XmlPath" -Tag "NewPatchFileTask"

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

<#

#>
function Invoke-AddPatchTask
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateScript ({Test-Path $_})]
		[string]$XmlPath,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[string]$Value,
		
		[string]$Comment
	)

	[xml]$XmlDocument = Get-Content -Path $XmlPath

	$sitecoreSettings = "//configuration/sitecore/settings"
 
	$appSettingsNode = $XmlDocument.SelectSingleNode($sitecoreSettings)
 
	if($appSettingsNode -eq $null)
	{
		$(throw "Sitecore Settings Does not Exists! Invalid Configuration File.")
	}

	$existingNode = $XmlDocument.SelectNodes("//configuration/sitecore/settings/setting") | Where-Object {$_ -ne $null -and $_.Name -eq $Name}
	if( $existingNode -ne $null )
	{
		Write-Verbose "Patch for setting $Name already exist"
		return
	}

	[System.Xml.XmlElement]$item = $XmlDocument.CreateElement("setting")
	$item.SetAttribute("name",  $Name)

	if( $Value -eq $null -or $Value -eq '')
	{
		$patch = $XmlDocument.CreateElement("patch","delete","http://www.sitecore.net/xmlconfig/") | Out-Null
		$item.AppendChild($patch)
	}
	else
	{
		$patch = $XmlDocument.CreateElement("patch","attribute","http://www.sitecore.net/xmlconfig/") | Out-Null
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
