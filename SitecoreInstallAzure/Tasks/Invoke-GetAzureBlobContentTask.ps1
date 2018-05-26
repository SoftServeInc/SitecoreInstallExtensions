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
		$fileName = Split-Path $blob -Leaf
		$destinationPath = Join-Path -Path $Destination -ChildPath $fileName

		if($pscmdlet.ShouldProcess($StorageName, "Download $Container\$blob => $destinationPath"))
		{
			if( -not (Test-Path $destinationPath ) )
			{
				$startTime = Get-Date
				Write-TaskInfo -Message "$Container\$blob => $destinationPath" -Tag 'Download'
				Get-AzureStorageBlobContent -Context $StorageContext -Container $Container -Blob $blob -Destination $destinationPath -Force | Out-Null
				$endTime = Get-Date
				$timeTaken = $endTime.Subtract($startTime)
				Write-Verbose "Time taken: $($timeTaken.TotalSeconds) seconds"
			}
			else
			{
				Write-Verbose -Message "$Destination already exists."
			}
		}
	}
}


function Invoke-DownloadAzureBlobContentTask
{
     [CmdletBinding(SupportsShouldProcess=$true)]
     Param
     (
        # The url to the Azure storage
        [Parameter(Mandatory=$true)]
		[string]
        $Url,
		
		# The SAS token for storage
		[Parameter(Mandatory=$true)]
		[string]
        $Token,

		# The Azure container name
        [string]
        $Container,

		# The list of files to download from Url\Container
        [string[]]
        $Blobs,
		
		# The local folder where blobs will be downloaded
        [string]
        $Destination
     )
	
	foreach( $blob in $Blobs )		
	{
		$fileName = Split-Path $blob -Leaf
		$destinationPath = Join-Path -Path $Destination -ChildPath $fileName

		if($pscmdlet.ShouldProcess($Url, "Download $Container\$blob => $destinationPath"))
		{
			if( -not (Test-Path $destinationPath ) )
			{
				$startTime = Get-Date
				Write-TaskInfo -Message "$Url\$Container\$blob => $destinationPath" -Tag 'Download'

				Add-Type -AssemblyName System.Web
				$blobUrl = $blob -replace " ","%20"

				$uri = "$Url/$Container/$blobUrl$Token"
				Invoke-WebRequest -Uri $uri -OutFile $destinationPath

				$endTime = Get-Date
				$timeTaken = $endTime.Subtract($startTime)
				Write-Verbose "Time taken: $($timeTaken.TotalSeconds) seconds"
			}
			else
			{
				Write-TaskInfo -Message "$Destination already exists." -Tag 'Download'
			}
		}
	}
}



Export-ModuleMember Invoke-GetAzureBlobContentTask
Export-ModuleMember Invoke-DownloadAzureBlobContentTask

Register-SitecoreInstallExtension -Command Invoke-DownloadAzureBlobContentTask -As DownloadBlobContent -Type Task


