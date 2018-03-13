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

	