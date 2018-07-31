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
		Write-TaskInfo "Patch for setting $Name already exist" -Tag "Patch"
		return
	}

	[System.Xml.XmlElement]$item = $XmlDocument.CreateElement("setting")
    if( $item -eq $null )
    {
        Write-Verbose "Cannot create element setting"
        return
    }
	$item.SetAttribute("name",  $Name)
    
    Write-TaskInfo -Message "Create patch for setting $Name = $Value" -Tag "Patch"
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

# SIG # Begin signature block
# MIIOJAYJKoZIhvcNAQcCoIIOFTCCDhECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKyuc0W7wpjBkZyned/vEJfoE
# SqagggtbMIIFczCCBFugAwIBAgIQUSxkhQ/4RLIK3tXEKSPpmzANBgkqhkiG9w0B
# AQsFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEj
# MCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25pbmcgQ0EwHhcNMTgwNTI4MDAw
# MDAwWhcNMTkwNTI4MjM1OTU5WjCBszELMAkGA1UEBhMCVVMxDjAMBgNVBBEMBTc4
# NzAxMQ4wDAYDVQQIDAVUZXhhczEPMA0GA1UEBwwGQXVzdGluMSQwIgYDVQQJDBsy
# MDEgVyA1dGggU3RyZWV0IFN1aXRlIDE1NTAxDjAMBgNVBBIMBTc4NzAxMRcwFQYD
# VQQKDA5Tb2Z0U2VydmUsIEluYzELMAkGA1UECwwCSVQxFzAVBgNVBAMMDlNvZnRT
# ZXJ2ZSwgSW5jMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtacjDf0a
# fiL/JjPhuusvx/wzxS4NdQWRwjDtPCPujWuf+IkB1oY4Nq+fACMlLMzTY7btMpEi
# 3po6UqRqxgXyaWp0lIdf/uuHNgAL5xzh4U17ChzaCI6kS5oiD3SLtmhv8iJh31s9
# XVe8PgMg/prKHgnkSfBwwL+q7xDjHZ64QVF7j8w8QPUhIe50kSeQKObCl9PoyIxL
# filF95MKvat69wBcidedDr1NuIT6zM1MY7IHdJJpckOjwbqmxDqJnMlMcleSXfb6
# c+MuEocRLU5ZBxFlE/HlDDTS55w2JTADqd9frpNNuW/BVsmIJb5wppYm7b8fYf0o
# Ztd6r81xKzIwCQIDAQABo4IBtjCCAbIwHwYDVR0jBBgwFoAUKZFg/4pN+uv5pmq4
# z/nmS71JzhIwHQYDVR0OBBYEFCEuZIvB3XxckO1wWP+/CaYTJ2TIMA4GA1UdDwEB
# /wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGCWCG
# SAGG+EIBAQQEAwIEEDBGBgNVHSAEPzA9MDsGDCsGAQQBsjEBAgEDAjArMCkGCCsG
# AQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21vZG8ubmV0L0NQUzBDBgNVHR8EPDA6
# MDigNqA0hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9DT01PRE9SU0FDb2RlU2ln
# bmluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPgYIKwYBBQUHMAKGMmh0dHA6Ly9j
# cnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNvZGVTaWduaW5nQ0EuY3J0MCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wJwYDVR0RBCAwHoEcc2Ft
# dGVhbW1haWxAc29mdHNlcnZlaW5jLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAEdJL
# WqG+vwl4lHQAWoMGAUmMpkBFiSPDy7fU7CSIFkdRnVRMVE2VCG2yJiTChBqreM5u
# IvZJvqSkMxxzcAbdR66OPVRunRXRo3I1Oxyb11f/4G39Qaw3LxH6JQOHh9g/w3av
# L9NR6S+vOhdK7PR+kkDA4rxHdh/1PQNX/5BjvtjZoW7Q6l3qwDH/XENdsk0i7oKm
# GeqoY2bjXWZ7Y2uBn9HlaJJOjn7sTgO94rT6YYpFa+TqFP9KY4/d+61tdz9M6K9Z
# yRgXyNbtMIPmSMqF7qh8z9/hfPsGY+2AkvgHnnsUFhPbckLdUN/0LDPRoAtIPTwi
# k2Oskgam6avYyryNPjCCBeAwggPIoAMCAQICEC58h8wOk0pS/pT9HLfNNK8wDQYJ
# KoZIhvcNAQEMBQAwgYUxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1h
# bmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBM
# aW1pdGVkMSswKQYDVQQDEyJDT01PRE8gUlNBIENlcnRpZmljYXRpb24gQXV0aG9y
# aXR5MB4XDTEzMDUwOTAwMDAwMFoXDTI4MDUwODIzNTk1OVowfTELMAkGA1UEBhMC
# R0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9y
# ZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBS
# U0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAppiQY3eRNH+K0d3pZzER68we/TEds7liVz+TvFvjnx4kMhEna7xRkafPnp4l
# s1+BqBgPHR4gMA77YXuGCbPj/aJonRwsnb9y4+R1oOU1I47Jiu4aDGTH2EKhe7VS
# A0s6sI4jS0tj4CKUN3vVeZAKFBhRLOb+wRLwHD9hYQqMotz2wzCqzSgYdUjBeVoI
# zbuMVYz31HaQOjNGUHOYXPSFSmsPgN1e1r39qS/AJfX5eNeNXxDCRFU8kDwxRstw
# rgepCuOvwQFvkBoj4l8428YIXUezg0HwLgA3FLkSqnmSUs2HD3vYYimkfjC9G7WM
# crRI8uPoIfleTGJ5iwIGn3/VCwIDAQABo4IBUTCCAU0wHwYDVR0jBBgwFoAUu69+
# Aj36pvE8hI6t7jiY7NkyMtQwHQYDVR0OBBYEFCmRYP+KTfrr+aZquM/55ku9Sc4S
# MA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMBEGA1UdIAQKMAgwBgYEVR0gADBMBgNVHR8ERTBDMEGgP6A9hjto
# dHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9DT01PRE9SU0FDZXJ0aWZpY2F0aW9uQXV0
# aG9yaXR5LmNybDBxBggrBgEFBQcBAQRlMGMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9j
# cnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUFkZFRydXN0Q0EuY3J0MCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZIhvcNAQEMBQADggIB
# AAI/AjnD7vjKO4neDG1NsfFOkk+vwjgsBMzFYxGrCWOvq6LXAj/MbxnDPdYaCJT/
# JdipiKcrEBrgm7EHIhpRHDrU4ekJv+YkdK8eexYxbiPvVFEtUgLidQgFTPG3UeFR
# AMaH9mzuEER2V2rx31hrIapJ1Hw3Tr3/tnVUQBg2V2cRzU8C5P7z2vx1F9vst/dl
# CSNJH0NXg+p+IHdhyE3yu2VNqPeFRQevemknZZApQIvfezpROYyoH3B5rW1CIKLP
# DGwDjEzNcweU51qOOgS6oqF8H8tjOhWn1BUbp1JHMqn0v2RH0aofU04yMHPCb7d4
# gp1c/0a7ayIdiAv4G6o0pvyM9d1/ZYyMMVcx0DbsR6HPy4uo7xwYWMUGd8pLm1Gv
# TAhKeo/io1Lijo7MJuSy2OU4wqjtxoGcNWupWGFKCpe0S0K2VZ2+medwbVn4bSoM
# fxlgXwyaiGwwrFIJkBYb/yud29AgyonqKH4yjhnfe0gzHtdl+K7J+IMUk3Z9ZNCO
# zr41ff9yMU2fnr0ebC+ojwwGUPuMJ7N2yfTm18M04oyHIYZh/r9VdOEhdwMKaGy7
# 5Mmp5s9ZJet87EUOeWZo6CLNuO+YhU2WETwJitB/vCgoE/tqylSNklzNwmWYBp7O
# SFvUtTeTRkF8B93P+kPvumdh/31J4LswfVyA4+YWOUunMYICMzCCAi8CAQEwgZEw
# fTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
# A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxIzAhBgNV
# BAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBAhBRLGSFD/hEsgre1cQpI+mb
# MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MCMGCSqGSIb3DQEJBDEWBBQ97SP5zO/buKtSuFjPwswOKUxQTjANBgkqhkiG9w0B
# AQEFAASCAQAnyVi7T1YCRtm7YhVv1wXBhiiu8cb1y+YaoxMGtXbUPvJWgThqtq1I
# Hel8uN3o6/oQye2teuwOPOUb4fUq/9q08jScqVn53axvsl4tKdHJujXWTUaqyn/8
# T+V/0C3cj1TWG4iy7cvy2T3lmj1PtaeKoIggD4B7oDO1oxUDxCYcFFtaIrdJq1/t
# vMS18DDxv25VrdZv6+7H1JpKujYHGsfA5/4bNLWCcVJzJplo5sGsLoUbLe5Xy3wW
# jHk5xbnTbNYE3LW+P3VRrXZjaScimGDn631r7sKSwgB7xTE3tgwo3MJDJMaQO4mg
# N7vu4zFeOGAusUwPUA7R0cKfFBD5ywcG
# SIG # End signature block
