# This task is copy&paste from SitecoreInstallFramework module
# We add action remove to remove Website
#Requires -Modules WebAdministration

Set-StrictMode -Version 2.0

Function Invoke-ManageWebsiteTaskEx {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet('start', 'stop','restart','remove')]
		[string]$Action
    )

    Function CheckWebsiteState {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name,
            [Parameter(Mandatory=$true)]
            [string]$RequiredState
        )

        try {
            Write-Verbose "Checking state of Website '$Name'"
            $currentState = Get-WebsiteState -Name $Name
        }
        catch {
            throw
        }

        if($currentState.Value -eq $RequiredState)
        {
            Write-Warning -Message "Website $Name is already $($currentState.Value)"
            return $false
        }

        return $true
    }

    Write-TaskInfo -Message $Name -Tag $Action

    $commandName = "$Action-Website"

    try {
        if($PSCmdlet.ShouldProcess($Name, $commandName)) {
            switch ($Action) {
                'start' {
                    if(CheckWebsiteState -Name $Name -RequiredState "Started") {
                        Write-Verbose "Starting Website '$Name'"
                        Start-Website -Name $Name
                    }
                }
                'restart' {
                    $currentState = Get-WebsiteState -Name $Name

                    if($currentState.Value -eq "Stopped") {
                        Write-Warning -Message "Website $Name is currently $($currentState.Value)"
                        Write-Verbose "Starting Website '$Name'"

                        Start-Website -Name $Name
                    }
                    else {
                        Write-Verbose "Stopping Website '$Name'"
                        Stop-Website -Name $Name

                        Write-Verbose "Starting Website '$Name'"
                        Start-Website -Name $Name
                    }
                }
                'stop' {
                    if(CheckWebsiteState -Name $Name -RequiredState "Stopped") {
                        Write-Verbose "Stopping Website '$Name'"
                        Stop-Website -Name $Name
                    }
                }
				'remove'{
					try
					{
						Get-WebsiteState -Name $Name
						Write-Verbose "Stopping Website '$Name'"
						Stop-Website -Name $Name
						Write-Verbose "Removing Website '$Name'"
						Remove-Website -Name $Name
					}
					catch 
					{
						Write-Warning "Site '$Name' not exist."
					}
					
				}
            }
        }
    }
    catch {
        Write-Error $_
    }
}

Export-ModuleMember Invoke-ManageWebsiteTaskEx