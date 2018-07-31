
Function Invoke-SetSqlMixedModeTask {
<#
.SYNOPSIS
	Enables a SQL Server Authentication.

.DESCRIPTION
	The Invoke-SetSqlMixedModeTask is registered as SetSqlMixedMode task.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"SetDbMixedMode": {
      "Type": "SetSqlMixedMode",
      "Params": {
        "SQLServerName": "[parameter('SqlServerName')]",
        "UserName": "[parameter('SqlUser')]",
        "Password": "[parameter('SqlPassword')]"
      }
    }
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
        [string]$UserName,
        [string]$Password
	)

	#region "Get MSSQL server instance"
	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName
	
	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
	#endregion
    
    if( -not ([string]::IsNullOrEmpty($UserName)))
    {
        $sqlServerSmo.ConnectionContext.LoginSecure = $false
        $sqlServerSmo.ConnectionContext.Login = $UserName
        $sqlServerSmo.ConnectionContext.Password = $Password
    }

	[string]$nm = $sqlServerSmo.Name
	[string]$mode = $sqlServerSmo.Settings.LoginMode

	Write-Verbose "Instance Name: $nm, login mode $mode"

	if($pscmdlet.ShouldProcess($SQLServerName, "Set server login mode ($mode) to mixed"))
    {
        if( $mode -ne "Mixed" )
        {
		    #Change to Mixed Mode
		    $sqlServerSmo.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed

		    # Make the changes
	    	$sqlServerSmo.Alter()
        }
	}

	if($pscmdlet.ShouldProcess($SQLServerName, "Restart"))
    {
		$service = Get-Service mssqlserver -ErrorAction SilentlyContinue

		if( $service -ne $null )
		{
			Restart-Service -Force "MSSQLSERVER"
		}

		$service = Get-Service SQLEXPRESS -ErrorAction SilentlyContinue

		if( $service -ne $null )
		{
			Restart-Service -Force "SQLEXPRESS"
		}
	}
}

<#
.SYNOPSIS
	Creates a login account on the instance of SQL Server

.DESCRIPTION
	The Invoke-CreateDbUserTask is registered as CreateDbUser task.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"CreateDatabaseUser": {
      "Type": "CreateDbUser",
      "Params": {
        "SQLServerName": "[parameter('SqlServerName')]",
        "UserName": "[parameter('SqlUser')]",
        "Password": "[parameter('SqlPassword')]"
      }
    }
#>
function Invoke-CreateSqlUserTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[string]$Password
	)

	Write-TaskInfo -Message "Create user $UserName on server $SQLServerName" -Tag 'MSSQL'

	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
    
    if( $UserName -eq "sa" )
	{
		Write-Warning "Skipping 'sa' user creation"
		return;
	}


	if($pscmdlet.ShouldProcess($SQLServerName, "Create user $UserName"))
    {
		$login = $sqlServerSmo.Logins[$UserName]
		if($login -eq $null)
		{
			$login = new-object Microsoft.SqlServer.Management.Smo.Login($sqlServerSmo.Name, $UserName)
			$login.LoginType = 'SqlLogin'
			$login.PasswordPolicyEnforced = $false
			$login.PasswordExpirationEnabled = $false
			$login.Create($Password)
			
		}
		else
		{
			Write-Warning "User exist: $UserName ..."
		}
	}
}

function Invoke-DeleteSqlUserTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string]$UserName
	)

	Write-TaskInfo -Message "Delete user $UserName on server $SQLServerName" -Tag 'MSSQL'

	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}

	if($pscmdlet.ShouldProcess($SQLServerName, "Delete user $UserName"))
    {
		$login = $sqlServerSmo.Logins[$UserName]
		if($login -eq $null)
		{
			Write-Warning "User $UserName not exist"
		}
		else
		{
			$login.DropIfExists()
		}
	}
}


<#
.SYNOPSIS
	Add a roles to the database user

.DESCRIPTION
	The Invoke-SqlSetDatabaseRolesTask function adds a roles to the specified database or databases.

	The Invoke-SqlSetDatabaseRolesTask is registered as SetDatabaseRoles task.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"AddRolesForDatabases": {
      "Type": "SetDatabaseRoles",
      "Params": {
        "SQLServerName": "[parameter('SqlServerName')]",
        "Databases": [
          "[variable('Sql.Database.Analytics')]",
          "[variable('Sql.Database.Master')]",
          "[variable('Sql.Database.Web')]"
        ],
        "Login": "[parameter('SqlUser')]",
        "Roles": [ "db_datareader", "db_datawriter", "public" ]
      }
    }

#>
function Invoke-SetSqlDatabaseRolesTask   {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string[]]$Databases,
		[Parameter(Mandatory=$true)]
		[string]$Login,
		[Parameter(Mandatory=$true)]
		[string[]]$Roles
	)

	#region "Get MSSQL server instance"
	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
	#endregion

    if ($Login -eq "sa")
    {
        Write-Warning "The login '$Login' is the built-in sysadmin for SQL. Skip setting roles for this user."
        return
    }

	foreach( $db in $Databases )
	{
		$database = $sqlServerSmo.Databases[$db]
		$dbUser = $database.Users | Where-Object {$_.Login -eq "$Login"}
		if ($dbUser -eq $null)
		{
			Write-TaskInfo -Message "Adding user $Login in $($database.Name)" -Tag 'MSSQL'

			$dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User($database, $Login)
			$dbUser.Login = $Login
			$dbUser.Create()
		}

		# Assign database roles user
		foreach ($roleName in $roles)
		{
			Write-TaskInfo -Message "Adding $roleName role for $($dbUser.Name) on $db" -Tag 'MSSQL'

			$dbrole = $database.Roles[$roleName]
			$dbrole.AddMember($dbUser.Name)
			$dbrole.Alter | Out-Null
		}
	}
}

function Invoke-AttachSqlDatabaseTask {
<#
.SYNOPSIS
	Attach a database to the MSSQL server.

.DESCRIPTION
	The Invoke-AttachSqlDatabaseTask attach 'DBDataFilePath' to 'SQLServerName' as 'DBName'.

	The Invoke-AttachSqlDatabaseTask is registered as AttachDB task.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

 "AttachCoreDatabase": {
      "Type": "AttachDB",
      "Params": {
        "SQLServerName": "[parameter('SqlServerName')]",
        "DBName": "[variable('Sql.Database.Core')]",
        "DBDataFilePath": "[variable('Sql.MDF.Core')]",
        "DBLogFilePath": "[variable('Sql.LDF.Core')]"
      }
    }
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string]$DBName,
		[Parameter(Mandatory=$true)]
		[string]$DBDataFilePath,
		[Parameter(Mandatory=$true)]
		[string]$DBLogFilePath
	)

	#region "Get MSSQL server instance"
	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
	#endregion

	if($pscmdlet.ShouldProcess($SQLServerName, "Attach $DBDataFilePath as database $DBName"))
    {
		if ($sqlServerSmo.databases[$DBName] -eq $null)
		{
			Write-TaskInfo -Message "Attaching $DBDataFilePath to $SQLServerName as $DBName" -Tag 'MSSQL'
			Write-TaskInfo -Message "Attaching $DBLogFilePath to $SQLServerName as $DBName" -Tag 'MSSQL'

			$files = New-Object System.Collections.Specialized.StringCollection 
			$files.Add($DBDataFilePath) | Out-Null; 
			$files.Add($DBLogFilePath) | Out-Null;

			# Try attaching
			try
			{
				$sqlServerSmo.AttachDatabase($DBName, $files)
			}
			catch
			{
				Write-Error $_.Exception
			}
		}
		else
		{
			$message = "Database $DBName already exists on " + $sqlServerSmo.Name
			Write-Warning $message
		}
	}

}


function Invoke-SetSqlDatabasePermisionsTask {

[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string[]]$Databases,
		[Parameter(Mandatory=$true)]
		[string]$UserName
	)

	#region "Get MSSQL server instance"
	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
	#endregion

	foreach( $db in $Databases )
	{
		$database = $sqlServerSmo.Databases[$db]
		if ($UserName -eq "sa")
		{
			Write-Warning "The login '$UserName' is the built-in sysadmin for SQL. Skip setting roles for this user."
			return
		}

		$dbUser = $database.Users | Where-Object {$_.Login -eq "$UserName"}

		if ($dbUser -eq $null)
		{
			Write-Warning "Could not find a user '$UserName' for the login . Cannot grant permissions."
			return
		}
	
		$permset = New-Object Microsoft.SqlServer.Management.Smo.DatabasePermissionSet 
		$permset.Execute = $true
		$database.Grant($permset, $UserName)
		$database.Alter();

		$message = "Granted Execute permission to $UserName on $db" 
		Write-TaskInfo -Message $message -Tag 'MSSQL'
	}
}


function Invoke-DeleteSqlDatabaseTask {
<#
.SYNOPSIS
	Removes a SQL databases on server

.DESCRIPTION
	The Invoke-DeleteSqlDatabaseTask  function removes a databases on MSSQL server.

	The Invoke-DeleteSqlDatabaseTask  is registered as SqlDeleteDatabase task.

.EXAMPLE
Json task configuration for Sitecore Install Framework
"DeleteDatabases": {
      "Type": "DeleteSqlDatabase",
      "Params": {
        "SQLServerName": "[parameter('SqlServerName')]",
        "Databases": [
          "[variable('Sql.Database.Analytics')]",
          "[variable('Sql.Database.Master')]",
          "[variable('Sql.Database.Web')]"
        ],
    }
}

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SQLServerName,
		[Parameter(Mandatory=$true)]
		[string[]]$Databases
	)

	#region "Get MSSQL server instance"
	$sqlServerSmo = Get-SqlServerSmo -SQLServerName $SQLServerName

	if( $sqlServerSmo -eq $null )
	{
		Write-Error "Cannot find MSSQL server $SQLServerName"
		return;
	}
	#endregion

	foreach( $database in $Databases )
	{
		if($pscmdlet.ShouldProcess($SQLServerName, "Remove $database"))
		{
			if ($sqlServerSmo.databases[$database] -ne $null)
			{
				Write-TaskInfo -Message "Remove $database" -Tag 'MSSQL'

				Invoke-SQLcmd -ServerInstance $SQLServerName -Query ("EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'" + $database + "'")
				Invoke-SQLcmd -ServerInstance $SQLServerName -Query ("DROP DATABASE [" + $database + "]")
			}
			else
			{
				$message = "Database $database not exists on $SQLServerName"
				Write-Warning $message
			}
		}
	}
}


$sql = @"
declare @ApplicationName nvarchar(256) = 'sitecore'
declare @UserName nvarchar(256) = 'sitecore\admin'
declare @Password nvarchar(128) = 'passwordplaceholder'
declare @HashAlgorithm nvarchar(10) = 'SHA2_512'
declare @PasswordFormat int = 1 -- Hashed
declare @CurrentTimeUtc datetime = SYSUTCDATETIME()
declare @Salt varbinary(16) = 0x
declare @HashedPassword varbinary(512)
declare @EncodedHash nvarchar(128)
declare @EncodedSalt nvarchar(128)

-- Generate random salt
while len(@Salt) < 16
begin
	set @Salt = (@Salt + cast(cast(floor(rand() * 256) as tinyint) as binary(1)))
end

-- Hash password
set @HashedPassword = HASHBYTES(@HashAlgorithm, @Salt + cast(@Password as varbinary(128)));

-- Convert hash and salt to BASE64
select @EncodedHash = cast(N'' as xml).value(
                  'xs:base64Binary(xs:hexBinary(sql:column("bin")))'
                , 'varchar(max)'
            ) from (select @HashedPassword as [bin] ) T

select @EncodedSalt = cast(N'' as xml).value(
                  'xs:base64Binary(xs:hexBinary(sql:column("bin")))'
                , 'VARCHAR(MAX)'
            ) from (select @Salt as [bin] ) T 

execute [dbo].[aspnet_Membership_SetPassword] 
   @ApplicationName
  ,@UserName
  ,@EncodedHash
  ,@EncodedSalt
  ,@CurrentTimeUtc
  ,@PasswordFormat

"@



function Invoke-SetSitecoreAdminPasswordTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$SqlServer,
		[Parameter(Mandatory=$true)]
		[string]$SqlDb,
		[Parameter(Mandatory=$true)]
		[string]$SqlAdminUser,
		[Parameter(Mandatory=$true)]
		[string]$SqlAdminPassword,
		[Parameter(Mandatory=$true)]
		[string]$SitecoreAdminPassword
	)

	if($pscmdlet.ShouldProcess($SqlServer, "Reset Sitecore admin password at database $SqlDb"))
    {
		Write-TaskInfo -Message "Reset Sitecore admin password at database $SqlDb" -Tag 'MSSQL'

		$query = $sql -replace 'passwordplaceholder',$SitecoreAdminPassword
		Invoke-SQLcmd -ServerInstance $SqlServer -Query $Query -Database $SqlDb -Username $SqlAdminUser -Password $SqlAdminPassword
	}
}


Export-ModuleMember Invoke-SetSqlMixedModeTask
Export-ModuleMember Invoke-AttachSqlDatabaseTask
Export-ModuleMember Invoke-DeleteSqlDatabaseTask
Export-ModuleMember Invoke-SetSqlDatabaseRolesTask
Export-ModuleMember Invoke-SetSqlDatabasePermisionsTask
Export-ModuleMember Invoke-CreateSqlUserTask
Export-ModuleMember Invoke-DeleteSqlUserTask
Export-ModuleMember Invoke-SetSitecoreAdminPasswordTask

Register-SitecoreInstallExtension -Command Invoke-SetSitecoreAdminPasswordTask -As SetSitecoreAdminPassword -Type Task





# SIG # Begin signature block
# MIIOJAYJKoZIhvcNAQcCoIIOFTCCDhECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUi6baPzHQvRwJsoSQKuk/tX5d
# CGugggtbMIIFczCCBFugAwIBAgIQUSxkhQ/4RLIK3tXEKSPpmzANBgkqhkiG9w0B
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
# MCMGCSqGSIb3DQEJBDEWBBRDIjxwNqFYVXsv1XFGEt3rQ7GRNDANBgkqhkiG9w0B
# AQEFAASCAQABlWVxyi/psoIdT5Jg09oAP6ionUeP/4X4tmB9aAisZ+KtNg4fmN1F
# /33zAgwEzuHlUP+VV7OdXCtOx959oKKa1Hq2/qqN9Q+v8Lu9ok1Pk9wtBi7oHdhm
# oZZhbNPWVveyVdEbdnTGi+ly5Wpo0aRbpC3UypyoTV7all569qUIfQy0wgxXLYZP
# exetOiWiTfhtktVJB4lmTzLskCXAitZyXefria+YUFb0i3Sbozm2liXNq18So844
# bhV76pikGd/BVG4QANt//SMQU+mNkYgE339abEqWcaI8E6D8NRSafKA0zHzQcfof
# 3IvQSRocwCcI94PtrW4XfVdtM6IpX4fH
# SIG # End signature block
