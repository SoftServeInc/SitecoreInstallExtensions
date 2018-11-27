
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
        Write-Verbose "Connect with MSSQL Authentication: ($UserName)"
        $sqlServerSmo.ConnectionContext.LoginSecure = $false
        $sqlServerSmo.ConnectionContext.Login = $UserName
        $sqlServerSmo.ConnectionContext.Password = $Password
    }
    else
    {
        Write-Verbose "Connect with Windows Authentication"
        $sqlServerSmo.ConnectionContext.LoginSecure = $true
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

	Write-Information -Message "Create user $UserName on server $SQLServerName" -Tag 'MSSQL'

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


	if($pscmdlet.ShouldProcess($SQLServerName, "Create user $UserName with sysadmin role"))
    {
		$login = $sqlServerSmo.Logins[$UserName]
		if($login -eq $null)
		{
			$login = new-object Microsoft.SqlServer.Management.Smo.Login($sqlServerSmo.Name, $UserName)
			$login.LoginType = 'SqlLogin'
			$login.PasswordPolicyEnforced = $false
			$login.PasswordExpirationEnabled = $false
			$login.AddToRole('sysadmin')
			$login.Create($Password)
			
		}
		else
		{
			$login.AddToRole('sysadmin')
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

	Write-Information -Message "Delete user $UserName on server $SQLServerName" -Tag 'MSSQL'

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
			Write-Information -Message "Adding user $Login in $($database.Name)" -Tag 'MSSQL'

			$dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User($database, $Login)
			$dbUser.Login = $Login
			$dbUser.Create()
		}

		# Assign database roles user
		foreach ($roleName in $roles)
		{
			Write-Information -Message "Adding $roleName role for $($dbUser.Name) on $db" -Tag 'MSSQL'

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
			Write-Information -Message "Attaching $DBDataFilePath to $SQLServerName as $DBName" -Tag 'MSSQL'
			Write-Information -Message "Attaching $DBLogFilePath to $SQLServerName as $DBName" -Tag 'MSSQL'

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
		Write-Information -Message $message -Tag 'MSSQL'
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
				Write-Information -Message "Remove $database" -Tag 'MSSQL'

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
		Write-Information -Message "Reset Sitecore admin password at database $SqlDb" -Tag 'MSSQL'

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





