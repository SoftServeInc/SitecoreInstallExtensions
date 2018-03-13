#
# GetConnectionStringElementConfigFunction.ps1
#

function Invoke-GetConnectionStringElementConfigFunction
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [string]$ConnectionStringsPath,
        [string]$ConnectionStringName,
		[ValidateSet('username', 'password','port','user id','Data Source','Database','connectionstring')]
		[string]$ParameterName
    )

	Write-Verbose "Processing $ConnectionStringsPath ($ConnectionStringName , $ParameterName)"
	
	$result = ""

	ForEach-Object {
		$connectionStringsFile = [xml](Get-Content $ConnectionStringsPath)

		foreach($connString in $connectionStringsFile.connectionStrings.add)
		{
			$name = $connString.name -eq $ConnectionStringName							  

			if($name)
			{
				if($connString.connectionString.Contains("mongodb"))
				{
					$uri = [System.Uri]$connString.connectionString
					Write-Verbose "Processing $uri"
					if($ParameterName -eq 'connectionstring')
					{
						$result = $uri
					}
					if ($ParameterName -eq "username")
					{
						$tab = $uri.UserInfo -split ":" 
						$result = $tab[0]
					}
					if ($ParameterName -eq "password")
					{
						$tab = $uri.UserInfo -split ":" 
						$result = $tab[1]
					}
					if ($ParameterName -eq "Data Source")
					{
						$result = $uri.Host	
					} 
					if ($ParameterName -eq "Database")
					{
						$string = $uri.LocalPath
						$result = $string.Split("/",[System.StringSplitOptions]::RemoveEmptyEntries)
					} 
					if ($ParameterName -eq "port")
					{
						$result = $uri.Port	
					}										 
				}
				else
				{			
					$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -argumentlist $connString.connectionString;
					$result = $builder[$ParameterName]
				}
			}
		}
	}		
	Write-Verbose "Result for parameter '$ParameterName': $result"
	return $result
}
 
Export-ModuleMember Invoke-GetConnectionStringElementConfigFunction

