#
# This script will install module in Powershell modules localization.
# Install means copy files from repo to $env:USERPROFILE\Documents\WindowsPowerShell\Modules\$moduleName"
#
$moduleName = "SitecoreInstallExtensions"
$projectFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionFolder = Split-Path -Parent $projectFolder
#$modulePath = Join-Path $projectFolder -ChildPath $moduleName 
$modulePath = "$moduleName"


#region Install module"

$userModules = Join-Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules\$moduleName"

if( -not (Test-Path -Path $userModules))
{
	md $userModules
}

Write-Output "SolutionFolder:" $solutionFolder
Write-Output "ProjectFolder:" $projectFolder
Write-Output "Source: $modulePath"
Write-Output "Path: $userModules"

Remove-Item "$userModules\*" -Verbose -Recurse -Force


md "$userModules\private" -Force 
md "$userModules\tasks" -Force 
md "$userModules\configfunctions" -Force
$filesToExclude = @( "install.ps1", "*.tests.ps1" )

# Verify Script Signatures 
$invalidSignatures = Get-ChildItem -Path $modulePath -Recurse -Include *.psd1, *.psm1, *.ps1  -Exclude $filesToExclude | ForEach-Object {Get-AuthenticodeSignature $_} | where {$_.status -ne "Valid"}

if( $invalidSignatures -ne $null )
{
	foreach( $invalidSignature in $invalidSignatures)
	{
		Write-Warning "Invalid signature: $($invalidSignature.Path)"
	}
}



Copy-Item -Path $modulePath\* -Destination "$userModules" -Include *.psd1, *.psm1, *.ps1, *.md -Exclude $filesToExclude   -Force -Verbose -Recurse 
Copy-Item -Recurse -Path $modulePath\private\* -Destination "$userModules\private" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose
Copy-Item -Recurse -Path $modulePath\tasks\* -Destination "$userModules\tasks" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose
Copy-Item -Recurse -Path $modulePath\configfunctions\* -Destination "$userModules\configfunctions" -Include *.psd1, *.psm1, *.ps1 -Exclude $filesToExclude -Force -Verbose


#endregion


#region Generate help
Import-Module SitecoreInstallExtensions -Force 

$commands = Get-Command -Module SitecoreInstallExtensions
$generateHelp = " $solutionFolder\GenerateHelp.ps1"
$documentationRoot = "https://github.com/SoftServeInc/SitecoreInstallExtensions/blob/master/Documentation"

$readme = Join-Path -Path "$solutionFolder\Documentation" -ChildPath "readme.md"

"> This file is autogenerated please updete doc in Powershell files`r`n" | Out-File -FilePath $readme
"# Tasks`r`n" | Out-File -FilePath $readme -Append

foreach ($comand in ($commands | Where-Object { $_.Name -notlike "*ConfigFunction*" }) )
{
	"* [$($comand.Name)]($documentationRoot/$($comand.Name).md)" | Out-File -FilePath $readme -Append
    &$generateHelp $comand.Name "$solutionFolder\Documentation"
}

"# Config Functions`r`n" | Out-File -FilePath $readme -Append

foreach ($comand in ($commands | Where-Object { $_.Name -like "*ConfigFunction*" }) )
{
	"* [$($comand.Name)]($documentationRoot/$($comand.Name).md)" | Out-File -FilePath $readme -Append
    &$generateHelp $comand.Name "$solutionFolder\Documentation"
}
#endregion