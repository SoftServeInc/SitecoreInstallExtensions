#Requires -Modules Azure
#Requires -Modules AzureRM


if(  (Get-Command Register-SitecoreInstallExtension -ErrorAction SilentlyContinue) -eq $null )
{
    Write-Warning "Sitecore Install Framework register command not exists" 
}
else
{
	#Tasks
	Register-SitecoreInstallExtension -Command Invoke-AzureLoginTask -As AzureLogin -Type Task
	Register-SitecoreInstallExtension -Command Invoke-GetAzureBlobContentTask -As GetBlobContent -Type Task
}