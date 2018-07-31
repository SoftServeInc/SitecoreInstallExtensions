#
# Invoke_EnsureMogoDbTask.ps1
#

Function Invoke-EnsureMogoDbTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# MongoMsi path to MongoDB installer
        [Parameter(Mandatory=$true)]
        $MongoPackage,

        # Path where you want to install MongoDB
        [Parameter(Mandatory=$true)]
        $InstallLocation,

        [Parameter(Mandatory=$true)]
        $DataPath
	)

	if($pscmdlet.ShouldProcess("MongoDB", "Verify if application is installed"))
    {
		#region Check if MongoDb is already installed
		$service = Get-Service | Where-Object {$_.name -eq "MongoDB"} 
  
		if( $service -ne $null -and $service.Status -eq 'Running' )
		{
			Write-Warning -Message "MongoDb is installed and running"
			return
		}
		#endregion
	}
	if($pscmdlet.ShouldProcess($MongoPackage, "Install application"))
    {
		$mongoPath = Join-Path -Path $InstallLocation -ChildPath "bin"

		$MSIArguments = @(
		"/i"
		('"{0}"' -f $MongoPackage)
		"/quiet"
		"INSTALLLOCATION=""$InstallLocation"""
		)

		Write-Verbose "Installing msi $MongoPackage"
    
		Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 

		if( -not (Test-Path $mongoPath) )
		{
			Write-Warning "Path $mongoPath not exist"
			return
		} 

		#region "Configuration files"
		Write-Verbose "Create configuration files"
		$dataPath = $DataPath

		$logPath = Join-Path -Path $dataPath  -ChildPath "log"
		$dbPath = Join-Path -Path $dataPath  -ChildPath "db"
		$configPath = Join-Path -Path $dataPath  -ChildPath "mongod.cfg"

		if( -not( Test-Path $configPath) )
		{
			New-Item $dataPath -type directory | Out-Null
			New-Item $logPath -type directory | Out-Null
			New-Item $dbPath  -type directory | Out-Null
			New-Item $configPath -type file | Out-Null

			Add-Content $configPath "systemLog:`n`r"
			Add-Content $configPath "    destination: file`n`r"
			Add-Content $configPath "    path: $logPath\mongod.log`n`r"
			Add-Content $configPath "storage:`n`r"
			Add-Content $configPath "    dbPath: $dbPath`n`r"
		}
		else
		{
			Write-Verbose "Configuration file $configPath already exists"
		}
		#endregion

		$args = @("--config", "$configPath", "--install")
		& "$mongoPath\mongod.exe" $args

		net start MongoDB

		$service = Get-Service | Where-Object {$_.name -eq "MongoDB"} 
		$service.Status
	}
}



Function Invoke-CreateMongoUserTask
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $UserName,
        [Parameter(Mandatory=$true)]
        $Password,
		[Parameter()]
		$HostName = 'localhost' ,
		[Parameter()]
		$Port = '27017',
        [Parameter(Mandatory=$true)]
		$DataBase
	)

$cmd = @"
db.createUser({ user: '$UserName', pwd: '$Password', roles: [ { role: 'dbAdmin', db: '$DataBase' } ] })
"@
	$cmd
	# Get path where MongoDb service is installed
	$service = Get-WmiObject win32_service | ?{$_.Name -eq 'MongoDB'} | select @{Name="Path"; Expression={$_.PathName.split('"')[1]}}
	$mongoBin = Split-Path -Parent $service.Path

	if( -not (Test-Path -Path $mongoBin) )
	{
		Write-Warning "Mongo Bin Path $mongoBin not exists"
		return
	}
    $mogoInstance = $HostName +':' + $Port +'/' + $DataBase 

	Invoke-Expression '& "$mongoBin\mongo.exe" $mongoInstance --eval $cmd --quiet'

}

Function Invoke-EnableFirewallTask
{
		[CmdletBinding(SupportsShouldProcess=$true)]
		param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $LocalPort,
        [Parameter(Mandatory=$true)]
        $DisplayName
	)

	New-NetFirewallRule `
    -DisplayName $DisplayName `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort $LocalPort `
    -Action Allow
}


Export-ModuleMember Invoke-EnsureMogoDbTask

	
# SIG # Begin signature block
# MIIOJAYJKoZIhvcNAQcCoIIOFTCCDhECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUObG8LTCnpLC+8gsOUIzUXtmt
# j+qgggtbMIIFczCCBFugAwIBAgIQUSxkhQ/4RLIK3tXEKSPpmzANBgkqhkiG9w0B
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
# MCMGCSqGSIb3DQEJBDEWBBSvXp3gng3C9CynRqm/x0BUFmYyqDANBgkqhkiG9w0B
# AQEFAASCAQCO6g/o/YKRUKwZjvOBS3QdtFZPF6b2ENxfBWP8dOGzedw1q8h1jMIi
# pH43+XcwSvud8qi7luAgD1cxZMBYbwi6ipBTXU5HJL/u82cyYpML79rv1xMOpGVq
# AjTVlqNYFRkReCtHDKVRIbLTTAxj72W0xmXeLm/jcaiNZ55gQxRUOYrILOGDLsuG
# 8sWNBxOEhPrayt0H/4Fn7C4oBYgyKA8uFBM1MR3gOx1mVXnQzZUSIQRY7w9+LHLJ
# kciFljeQhMkVPzaykVBwo7BzNyVh3quIi/PD0tCJUo+yfCYVR+g+KnF6Vh03D272
# CNNH1M8Ed7aRe3/rMdEAZwrrFmQiHwLD
# SIG # End signature block
