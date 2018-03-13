#
# Invoke-AzureLoginTask.ps1
#
Function Invoke-AzureLoginTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# The name of your Azure Subscription
		[Parameter(Mandatory=$true)]
		[string]$AzureSubscription,
		# Force login, useful when you change password
		[switch]$Force
	)

	#region Login
	$profileFilePath = "$env:USERPROFILE\Documents\azurecontext.json"

	if($pscmdlet.ShouldProcess($profileFilePath, "Load context from file"))
    {
		if( Test-Path $profileFilePath)
		{
			if( $Force -eq $true )
			{
				Remove-Item -Path $profileFilePath
			}
			Import-AzureRmContext -Path $profileFilePath | Out-Null
		}
	}

	if($pscmdlet.ShouldProcess($AzureSubscription, "Login to Azure account with subscription"))
    {
		$azureContext = Get-AzureRmContext
		if( $azureContext.Subscription -eq $null )
		{
			Add-AzureRmAccount 
			Set-AzureRmContext -Subscription $AzureSubscription
			Save-AzureRmContext -Path $profileFilePath
		}
	}
	#endregion
}


Export-ModuleMember Invoke-AzureLoginTask