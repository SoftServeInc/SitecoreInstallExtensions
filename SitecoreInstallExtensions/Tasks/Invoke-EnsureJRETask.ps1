#
# Invoke_EnsureJRETask.ps1
#
Set-StrictMode -Version 2.0

#Java SE Runtime Environment
Function Invoke-EnsureJRETask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$JavaPackagePath
	)
	
	#region "Verify JAVA_HOME variable"
	$javaHomeUser = [environment]::GetEnvironmentVariable("JAVA_HOME",[EnvironmentVariableTarget]::User)

	$javaHome = [environment]::GetEnvironmentVariable("JAVA_HOME",[EnvironmentVariableTarget]::Machine)

	if( $javaHome -ne $null -and $javaHomeUser -ne $null -and $javaHomeUser -ne $javaHome ) {
		Write-Error "JAVA_HOME environment variable has different value on System ($javaHome) and User ($javaHomeUser) level."
	}

	#endregion

	if($pscmdlet.ShouldProcess($javaHome, "Verify if JRE is installed"))
    {
		if( $javaHome -eq $null -or -not (Test-Path -Path $javaHome))
		{
			[environment]::SetEnvironmentVariable("JAVA_HOME",$null,[EnvironmentVariableTarget]::Machine)   
			Write-Warning "Java is not installed (Solr requires JRE)"
 
			$MSIArguments = @(
				"/s"
			)
  
			Write-Verbose "Start installing Java: $JavaPackagePath"  

			if( -not (Test-Path -Path $JavaPackagePath ) ) { Write-Error "$JavaPackagePath not exists!"  return}
      
			Start-Process $JavaPackagePath -ArgumentList $MSIArguments -Wait -NoNewWindow
			
			$items = @()
			$items += Get-ChildItem -Path $env:ProgramFiles -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue -ErrorVariable searchError
			
			if( $items.Count -eq 1 )
			{
				Write-Verbose "$items"
				$javaHome  = Split-Path -Parent $items.Directory.FullName
			}
			else
			{
				Write-Verbose "Ambigous Java installation $items"
				$javaPath = $items | Out-GridView -PassThru
				$javaHome  = Split-Path -Parent $javaPath.Directory.FullName
			}
			
			[environment]::SetEnvironmentVariable("JAVA_HOME",$javaHome,[EnvironmentVariableTarget]::Machine)   
			Write-Verbose "JAVA installed $javaHome"
		}
		else
		{
			$message = "JAVA already installed $javaHome" 
			Write-Host $message  
		}
	}
}

Export-ModuleMember Invoke-EnsureJRETask
# SIG # Begin signature block
# MIIOJAYJKoZIhvcNAQcCoIIOFTCCDhECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDDvRf7Zmhs9A+Z3a//tTWkjY
# 3q+gggtbMIIFczCCBFugAwIBAgIQUSxkhQ/4RLIK3tXEKSPpmzANBgkqhkiG9w0B
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
# MCMGCSqGSIb3DQEJBDEWBBRY0M+ViQjdpe5RaWKbFuS5KBsd+jANBgkqhkiG9w0B
# AQEFAASCAQBl/dC/5nuA88yMProN0EkgQ+6Wn5Pe48H4vckkAw4ThNQZ4XVz2non
# YEsv57enBWEWi5ei0Sm7Nw++PT9S3bgXT2z74ca9MrcgE1xzjuMXLMsiYTYm10n9
# 0282aZnMgR75966qim0ascHYSW0weYtzCvdkYdKwLNZxQ10iRN+h9nY97TpxNRDh
# Gx+KASAw4hSttsczb/0qRJqRwfcoHJkJMs07R+/bqmuae0Ug6XQ3QtcH3gfMmhZl
# sGvk7KdsXUaaHVbUh9ywc07VhhqsNutJlzvHABlO/4AZnwsQ6RwMAwEJl1j0JBbt
# mE1JEr9ngza0V7koTVkE3YUZ6QBWkhrZ
# SIG # End signature block
