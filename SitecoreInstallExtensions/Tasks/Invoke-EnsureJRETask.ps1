#
# Invoke_EnsureJRETask.ps1
#
Set-StrictMode -Version 2.0

#Java SE Runtime Environment
Function Invoke-EnsureJRETask {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$JavaPackagePath
	)
	
	#region "Verify JAVA_HOME variable"
	$javaHomeUser = [environment]::GetEnvironmentVariable("JAVA_HOME",[EnvironmentVariableTarget]::User)

	$javaHome = [environment]::GetEnvironmentVariable("JAVA_HOME",[EnvironmentVariableTarget]::Machine)

	if( $javaHome -ne $null -and $javaHomeUser -ne $null -and $javaHomeUser -ne $javaHome ) {
		Write-Error "JAVA_HOME environment variable has different value on System ($javaHome) and User ($javaHomeUser) level."
	}

	#endregion

	if($pscmdlet.ShouldProcess($javaHome, "Verify if JRE is installed"))
    {
		if( $javaHome -eq $null -or -not (Test-Path -Path $javaHome))
		{
			[environment]::SetEnvironmentVariable("JAVA_HOME",$null,[EnvironmentVariableTarget]::Machine)   
			Write-Warning "Java is not installed (Solr requires JRE)"
 
			$MSIArguments = @(
				"/s"
			)
  
			Write-Verbose "Start installing Java: $JavaPackagePath"  

			if( -not (Test-Path -Path $JavaPackagePath ) ) { Write-Error "$JavaPackagePath not exists!"  return}
      
			Start-Process $JavaPackagePath -ArgumentList $MSIArguments -Wait -NoNewWindow
			
			$items = @()
			$items += Get-ChildItem -Path $env:ProgramFiles -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue -ErrorVariable searchError
			
			if( $items.Count -eq 1 )
			{
				Write-Verbose "$items"
				$javaHome  = Split-Path -Parent $items.Directory.FullName
			}
			else
			{
				Write-Verbose "Ambigous Java installation $items"
				$javaPath = $items | Out-GridView -PassThru
				$javaHome  = Split-Path -Parent $javaPath.Directory.FullName
			}
			
			[environment]::SetEnvironmentVariable("JAVA_HOME",$javaHome,[EnvironmentVariableTarget]::Machine)   
			Write-Verbose "JAVA installed $javaHome"
		}
		else
		{
			$message = "JAVA already installed $javaHome" 
			Write-Host $message  
		}
	}
}

Export-ModuleMember Invoke-EnsureJRETask

