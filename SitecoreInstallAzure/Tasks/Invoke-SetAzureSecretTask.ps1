
Function Invoke-SetAzureSecretTask {
<#
.SYNOPSIS
	Creates a secret to Azure key vault.

.DESCRIPTION
	

.EXAMPLE
	$Tags = @{ "Purpose" = "deployment" ; "DeploymentId" = "1234" }
	Invoke-SetAzureSecretTask -VaultName "sitecoredeployment" -SecretName "Password" -SecretValue $password -Tags $Tags

.NOTE
	You must be logged to Azure account by Invoke-AzureLoginTask

#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		# The name of your Azure Subscription
		[Parameter(Mandatory=$true)]
		[string]$VaultName ,
		[Parameter(Mandatory=$true)]
		[string]$SecretName ,
		[Parameter(Mandatory=$true)]
		[string]$SecretValue,
		[AllowEmptyCollection()]
        [hashtable]$Tags
	)

	if($pscmdlet.ShouldProcess($VaultName, "Create secret value $SecretName in "))
    {
		$Secret = ConvertTo-SecureString -String $SecretValue -AsPlainText -Force
		Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $Secret -Tag $Tags
	}
}


Export-ModuleMember Invoke-SetAzureSecretTask
Register-SitecoreInstallExtension -Command Invoke-SetAzureSecretTask -As SetSecret -Type Task