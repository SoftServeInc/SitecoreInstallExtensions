#
# Invoke_PowershellTask.ps1
#
Set-StrictMode -Version 2.0

Function Invoke-BackupFileTask {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$false)]
        [boolean]$AddDateTimeToFileName
    )

    if($pscmdlet.ShouldProcess($FilePath, "Backup file"))
    {
        if (![System.IO.File]::Exists($FilePath))
        {
            Write-TaskInfo -Message "File $FilePath does not exist" -Tag Warning 
            Return
        }

        $fileProperty = Get-ItemProperty -Path $FilePath

        $backupFilePath = $FilePath;
        
        if ($AddDateTimeToFileName) {
            $backupFilePath +="_$(get-date -f yyyyMMddHHmmss)"
        }

        Write-TaskInfo "Creating backup of $FilePath as $backupFilePath.bak" -Tag "Info"

        Copy-Item $FilePath -Destination "$backupFilePath.bak" -Force
    }
}

Export-ModuleMember Invoke-BackupFileTask
