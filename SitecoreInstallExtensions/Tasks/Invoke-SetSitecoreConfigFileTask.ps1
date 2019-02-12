#
# Invoke_SetSitecoreConfigFileTask.ps1
#
function Invoke-SetSitecoreConfigFileTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(        
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ConfigDir,
        
        [string[]]$ConfigFileListToEnable,
        
        [string[]]$ConfigFileListToDisable
    )	
   
	foreach ($configFileName in $ConfigFileListToEnable)
    {
        if($pscmdlet.ShouldProcess($configFileName, "Enable config file"))
        {
	    
        Write-Information "Enabling config file: $configFileName"

	    $configFilePath = Join-Path $ConfigDir -ChildPath $configFileName
	    $disabledFilePath = "$configFilePath.disabled";
	    $exampleFilePath = "$configFilePath.example";

	    if (Test-Path $configFilePath) 
        {
		    Write-Verbose "  config file is already enabled...";
	    } 
        elseif (Test-Path $disabledFilePath) 
        {
		    Rename-Item -Path $disabledFilePath -NewName $configFileName;
		    Write-Verbose "  successfully enabled $disabledFilePath";
	    }
        elseif (Test-Path $exampleFilePath) 
        {
		    Rename-Item -Path $exampleFilePath -NewName $configFileName;
		    Write-Verbose "  successfully enabled $exampleFilePath";
	    } 
        else
        {
		    Write-Verbose "  configuration file not found."
	    }
        }
    }

    foreach ($configFileName in $ConfigFileListToDisable)
    {
        if($pscmdlet.ShouldProcess($configFileName, "Disable config file"))
        {
	    
        Write-Information "Disabling config file: $configFileName"

	    $configFilePath = Join-Path $ConfigDir -ChildPath $configFileName
	    $disabledFilePath = "$configFilePath.disabled";
	   

	    if (Test-Path $disabledFilePath) 
        {
		    Write-Verbose "  config file is already disabled...";
	    } 
        elseif (Test-Path $configFilePath) 
        {
		    Rename-Item -Path $configFileName  -NewName $disabledFilePath;
		    Write-Verbose "  successfully disabled $disabledFilePath";
	    }
        else
        {
		    Write-Verbose "  configuration file not found."
	    }
        }
    }

}

Export-ModuleMember Invoke-SetSitecoreConfigFileTask
Register-SitecoreInstallExtension -Command Invoke-SetSitecoreConfigFileTask -As SetSitecoreConfigFile -Type Task

