# 
# Update local installed PowerShell module from public Git repository
#
param (
    [string]$ModuleName = "SitecoreInstallExtensions", 
    [string]$BranchName = "develop", 
    [string]$GitHubRoot = "https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/$BranchName/SitecoreInstallExtensions"
)

$moduleRoot = Split-Path (Get-Module -ListAvailable $ModuleName).Path
$moduleItems = Get-ChildItem -Recurse $moduleRoot
 
 foreach( $moduleItem in $moduleItems )
 {
    if( $moduleItem.Attributes -ne "Directory" )
    {
        $relativePath = $moduleItem.FullName.Replace($moduleRoot,'')
        $relativePath = $relativePath.Replace("configfunctions","ConfigFunctions")
        $relativePath = $relativePath.Replace("private","Private")
        $relativePath = $relativePath.Replace("tasks","Tasks")
        Invoke-WebRequest -Uri "$GitHubRoot$relativePath" -OutFile $moduleItem.FullName  -Verbose
    }
 }
