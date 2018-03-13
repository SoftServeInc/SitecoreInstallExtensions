#
# Invoke_GetAzureBlobContentTask.ps1
#
function Invoke-GetAzureBlobContentTask
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
        [string]
        $Container,

		# The list of files to download from StorageName\Container
        [string[]]
        $Blobs,
		
		# The local folder where blobs will be downloaded
        [string]
        $Destination
     )
	
	$storageAccount = $null

	if($pscmdlet.ShouldProcess($StorageName, "Connect to the storage"))
    {
		$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -ev notPresent -ea SilentlyContinue


		#We need a storage, so stop execution here if storage not exist or cannot be created.
		if( $storageAccount -eq $null ) 
		{ 
			Write-Warning "StorageAccount $StorageName not exists on Azure account"
			return 
		}
	}

	$StorageContext = $storageAccount.Context

	foreach( $blob in $Blobs )		
	{
		$destinationPath = Join-Path -Path $Destination -ChildPath $blob

		if($pscmdlet.ShouldProcess($StorageName, "Download $Container\$blob => $destinationPath"))
		{
			if( -not (Test-Path $destinationPath ) )
			{
				Write-TaskInfo -Message "$Container\$blob => $destinationPath" -Tag 'Download'
				Get-AzureStorageBlobContent -Context $StorageContext -Container $Container -Blob $blob -Destination $destinationPath -Force | Out-Null
			}
			else
			{
				Write-Verbose -Message "$Destination already exists."
			}
		}
	}
}

Export-ModuleMember Invoke-GetAzureBlobContentTask

