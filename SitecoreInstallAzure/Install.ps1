#
# Install.ps1
#
#
# This script will install module in Powershell modules localization.
# Install means copy files from repo to $env:USERPROFILE\Documents\WindowsPowerShell\Modules\$moduleName"
#
$moduleName = "SitecoreInstallAzure"
$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
#$modulePath = Join-Path $projectFolder -ChildPath $moduleName 
$modulePath = "$moduleName"

Write-Output $modulePath 

$userModules = Join-Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules\$moduleName"

if( -not (Test-Path -Path $userModules))
{
	md $userModules
}

Write-Output "Source: $modulePath"
Write-Output "Path: $userModules"

Remove-Item "$userModules\*" -Verbose -Recurse -Force

md "$userModules\private" -Force 
md "$userModules\tasks" -Force 
md "$userModules\configfunctions" -Force
$filesToExclude = @( "install.ps1", "*.tests.ps1" )

Copy-Item -Path $modulePath\* -Destination "$userModules" -Include *.psd1, *.psm1, *.ps1, *.md -Exclude $filesToExclude   -Force -Verbose -Recurse 
Copy-Item -Recurse -Path $modulePath\private\* -Destination "$userModules\private" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose
Copy-Item -Recurse -Path $modulePath\tasks\* -Destination "$userModules\tasks" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose
Copy-Item -Recurse -Path $modulePath\configfunctions\* -Destination "$userModules\configfunctions" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose

