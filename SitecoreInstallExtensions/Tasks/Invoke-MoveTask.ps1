#
# Invoke_MoveTask.ps1
#
Function Invoke-MoveTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(        
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path $_ })]
		[string]$Source,
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path $_ -IsValid })]
		[string]$Destination
	)

	$destRoot = Split-Path $Destination
	if(-not(Test-Path $destRoot)) {
		Write-Verbose "Destination path '$destRoot' does not exist"
		Write-Verbose "Creating '$destRoot'"
		New-Item $destRoot -ItemType Directory
	}

	Write-TaskInfo -Message "$Source => $Destination" -Tag 'Moving'
	Write-Verbose "Moving '$Source' to '$Destination'"
	Move-Item -Path $Source -Destination $Destination -Force
}


Function Invoke-RemoveTask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(        
		[Parameter(Mandatory=$true)]
		[string]$Source
	)

	Write-TaskInfo -Message "Remove $Source" -Tag 'Removing'
	Write-Verbose "Removing '$Source'"
	if( Test-Path -Path $Source )
	{
		Remove-Item -Path $Source -Force -Recurse
	}
}


Export-ModuleMember Invoke-MoveTask
Export-ModuleMember Invoke-RemoveTask