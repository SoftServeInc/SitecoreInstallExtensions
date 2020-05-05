Set-StrictMode -Version 2.0

Function Invoke-ExtractTask {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path $_ -Type Leaf })]
        [string]$Source,
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path $_ -Type Container })]
        [string]$Destination
    )

    Write-TaskInfo -Message "$Source => $Destination" -Tag 'Processing'

    if($PSCmdlet.ShouldProcess($Source, "Invoke-ExtractTask -Source $Source -Destination $Destination")) {
        Write-Verbose "Extracting Archive $Source to $Destination"
       
        Add-Type -assembly System.IO.Compression.Filesystem
        [io.compression.zipfile]::ExtractToDirectory($Source, $Destination)
    }
}

Export-ModuleMember Invoke-ExtractTask
