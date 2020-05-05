#Requires -RunAsAdministrator

# Get Functions
#Write-Host $PSScriptRoot

$private = Get-ChildItem -Path (Join-Path $PSScriptRoot Private) -Include *.ps1 -File -Recurse
#$public = Get-ChildItem -Path (Join-Path $PSScriptRoot Public) -Include *.ps1 -File -Recurse

# Dot source to scope
# Private must be sourced first - usage in public functions during load
($private) | ForEach-Object {
    try {
		#Write-Host $_.FullName
        . $_.FullName
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

if(  $null -eq (Get-Command Register-SitecoreInstallExtension -ErrorAction SilentlyContinue) )
{
    Write-Warning "Sitecore Install Framework register command not exists" 
}
else
{
	#Tasks
	Register-SitecoreInstallExtension -Command Invoke-ExeTask -As Exe -Type Task
	Register-SitecoreInstallExtension -Command Invoke-MoveTask -As Move -Type Task
	Register-SitecoreInstallExtension -Command Invoke-RemoveTask -As Remove -Type Task
	Register-SitecoreInstallExtension -Command Invoke-BackupFileTask -As BackupFile -Type Task
	Register-SitecoreInstallExtension -Command Invoke-ExtractTask -As Exe -Type Task

	Register-SitecoreInstallExtension -Command Invoke-EnsureJRETask -As EnsureJRE -Type Task
	Register-SitecoreInstallExtension -Command Invoke-EnsureMogoDbTask -As EnsureMongoDb -Type Task
	Register-SitecoreInstallExtension -Command Invoke-EnsureSolrTask -As EnsureSolr -Type Task
	Register-SitecoreInstallExtension -Command Install-SolrAsService -As SolrAsService -Type Task
	Register-SitecoreInstallExtension -Command Remove-SolrService -As RemoveSolrService -Type Task

	Register-SitecoreInstallExtension -Command Invoke-SetSqlMixedModeTask -As SetSqlMixedMode -Type Task
	Register-SitecoreInstallExtension -Command Invoke-CreateSqlUserTask -As CreateSqlUser -Type Task
	Register-SitecoreInstallExtension -Command Invoke-DeleteSqlUserTask -As DeleteSqlUser -Type Task
	Register-SitecoreInstallExtension -Command Invoke-AttachSqlDatabaseTask -As AttachSqlDatabase -Type Task
	Register-SitecoreInstallExtension -Command Invoke-DeleteSqlDatabaseTask -As DeleteSqlDatabase -Type Task
	Register-SitecoreInstallExtension -Command Invoke-SetSqlDatabasePermisionsTask -As GrantSqlPermissions -Type Task
	Register-SitecoreInstallExtension -Command Invoke-SetSqlDatabaseRolesTask -As SetSqlDatabaseRoles -Type Task
	
	Register-SitecoreInstallExtension -Command Invoke-InstallChocolateyPackageTask -As InstallChocolateyPackage -Type Task
	Register-SitecoreInstallExtension -Command Invoke-InstallPackageTask -As InstallSitecorePackage -Type Task
	
	Register-SitecoreInstallExtension -Command Invoke-DropMongoDatabaseTask -As DropMongoDatabase -Type Task

	#ConfigFunctions
	Register-SitecoreInstallExtension -Command Invoke-MongoConnectionStringConfigFunction -As MongoConnectionString -Type ConfigFunction
	Register-SitecoreInstallExtension -Command Invoke-GetConnectionStringElementConfigFunction -As ConnectionStringSettings -Type ConfigFunction


	#Overwrite orginal Sitecore Install Framework tasks and add remove option
	Register-SitecoreInstallExtension -Command Invoke-ManageAppPoolTaskEx -As ManageAppPool -Type Task -Force
	Register-SitecoreInstallExtension -Command Invoke-ManageWebsiteTaskEx -As ManageWebsite -Type Task -Force
}




