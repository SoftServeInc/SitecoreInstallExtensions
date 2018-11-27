#
# Invoke_DropMongoDatabaseTask.ps1
#

function Get-MongoPath{

	$mongoPath = (Get-Process -Name mongod -ErrorAction SilentlyContinue).Path
	if( -not [String]::IsNullOrEmpty($mongoPath) )
	{
		$mongoRoot = Split-Path $mongoPath -Parent
		return Join-Path $mongoRoot -ChildPath 'mongo.exe'
	}
    else
    {
        Write-Warning "Mongod process is not running"
    }

}

function Invoke-DropMongoDatabaseTask {
<#
.SYNOPSIS
	Drops specified Mongo database

.DESCRIPTION
	The Invoke-DropMongoDatabaseTask is registered as DropMongoDatabase type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"DeleteMongoDb": {
      "Type": "DropMongoDatabase",
      "Params": {
        "$DatabaseConnectionString":  
      }
    }

.EXAMPLE
	Invoke-DropMongoDatabaseTask -DatabaseConnectionString "mongodb://localhost:27017/Sitecore_tracking_live"
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$DatabaseConnectionString,
		[string]$MongoExe = { Get-MongoPath }
	)

	$cmdDeleteDb = @"
db.dropDatabase()
"@

	$mongoExe = Get-MongoPath

	if($pscmdlet.ShouldProcess($DatabaseConnectionString, "Execute drop database"))
    {
		Write-Information "Drop database $DatabaseConnectionString" -Tag "Info"

		Invoke-Expression '& "$mongoExe" $DatabaseConnectionString --eval $cmdDeleteDb --quiet'
	}
}

Export-ModuleMember Invoke-DropMongoDatabaseTask

