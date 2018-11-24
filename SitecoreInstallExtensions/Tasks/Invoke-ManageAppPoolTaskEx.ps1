# This task is copy&paste from SitecoreInstallFramework module
# We add action remove to remove AppPool
#Requires -Modules WebAdministration

Set-StrictMode -Version 2.0

Function Invoke-ManageAppPoolTaskEx {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet('start', 'stop', 'restart', 'remove')]
		[string]$Action
    )

    Function CheckAppPoolState {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name,
            [Parameter(Mandatory=$true)]
            [string]$RequiredState
        )

        try {
            Write-Verbose "Checking state of App Pool '$Name'"
            $currentState = Get-WebAppPoolState -Name $Name
        } catch {
            throw
        }

        if($currentState.Value -eq $RequiredState) {
            Write-Warning -Message "App Pool $Name is already $($currentState.Value)"
            return $false
        }

        return $true
    }

    Write-Information -Message $Name -Tag $Action

    $commandName = "$Action-WebAppPool"

    try {
        if($PSCmdlet.ShouldProcess($Name, $commandName)) {
            switch ($Action) {
                'start' {
                    if(CheckAppPoolState -Name $Name -RequiredState "Started")
                    {
                        Write-Verbose "Starting App Pool '$Name'"
                        Start-WebAppPool -Name $Name
                    }
                }
                'stop' {
                    if(CheckAppPoolState -Name $Name -RequiredState "Stopped")
                    {
                        Write-Verbose "Stopping App Pool '$Name'"
                        Stop-WebAppPool -Name $Name
                    }
                }
                'restart' {
                    $currentState = Get-WebAppPoolState -Name $Name

                    if($currentState.Value -eq "Stopped") {
                        Write-Warning -Message "App Pool $Name is currently $($currentState.Value)"
                        Write-Verbose "Starting App Pool '$Name'"
                        Start-WebAppPool -Name $Name
                    }
                    else {
                        Write-Verbose "Restarting App Pool '$Name'"
                        Restart-WebAppPool -Name $Name
                    }
                }
				'remove' {

					try
					{
						Get-WebAppPoolState -Name $Name
						Write-Verbose "Stopping App Pool '$Name'"
						Stop-WebAppPool -Name $Name
						Write-Verbose "Removing App Pool '$Name'"
						Remove-WebAppPool -Name $name
					}
					catch
					{
						Write-Warning -Message "App Pool $Name not exist"
					}
					
				}
            }
        }
    }
    catch {
        Write-Error $_
    }
}

Export-ModuleMember Invoke-ManageAppPoolTaskEx

