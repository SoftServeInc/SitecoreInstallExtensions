#
# Invoke_ListAzureContainerTask.ps1
#
function Invoke-ListAzureContainerTask
{
     [CmdletBinding(SupportsShouldProcess=$true)]
     Param
     (
        # The Azure resource group name where the storage is located
        [Parameter(Mandatory=$true)]
        $ResourceGroupName,
		
		# The Azure storage name
		[Parameter(Mandatory=$true)]
        $StorageName,

		# The Azure container name
		[Parameter(Mandatory=$true)]
        [string]
        $Container
     )

	if($pscmdlet.ShouldProcess($StorageName, "List blobs in container '$Container'"))
	{

		$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -ev notPresent -ea SilentlyContinue


		Get-AzureStorageContainer -Name $Container -Context $storageAccount.Context | Get-AzureStorageBlob | % { Write-TaskInfo -Message $_.Name -Tag $Container } 

	}
}

Export-ModuleMember Invoke-ListAzureContainerTask
Register-SitecoreInstallExtension -Command Invoke-ListAzureContainerTask -As ListContainerContent -Type Task