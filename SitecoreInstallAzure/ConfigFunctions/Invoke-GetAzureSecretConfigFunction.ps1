#requires -module AzureRM.KeyVault

function Invoke-GetAzureSecretConfigFunction
{
<#
.SYNOPSIS
	Gets the secrets from Azure key vault.

.DESCRIPTION
	The function Invoke-GetAzureSecretConfigFunction can return plain text or secure string depends on PlainText parameter.

.EXAMPLE
	PS:>Invoke-GetAzureSecretConfigFunction -VaultName "sitecoredeployment" -SecretName "Password"

.EXAMPLE
	PS:>Invoke-GetAzureSecretConfigFunction -VaultName "sitecoredeployment" -SecretName "Password" -PlainText $false

.NOTE
	You must be logged to Azure account by Invoke-AzureLoginTask

.NOTE
	https://docs.microsoft.com/en-us/powershell/module/azurerm.keyvault/Get-AzureKeyVaultSecret

#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true)]
        [string]$VaultName,
		[Parameter(Mandatory=$true)]
        [string]$SecretName,
		[bool]$PlainText = $true
    )
	
	Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand
    Write-Verbose -Message "Get $SecretName from $VaultName"

	if( $PlainText -eq $true ){
		return (Get-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName).SecretValueText
	}
	else
	{
		return (Get-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName).SecretValue
	}
}

Export-ModuleMember Invoke-GetAzureSecretConfigFunction
Register-SitecoreInstallExtension -Command Invoke-GetAzureSecretConfigFunction -As GetSecret -Type ConfigFunction

