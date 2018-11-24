#
# Select-WebSite.ps1
#

function Select-WebSite {

    $selectedWebSite = (Get-WebSite | Out-GridView -Title "Please select website to uninstall" -OutputMode Single )

    Write-Verbose $selectedWebSite

    $physicalPath =  [System.Environment]::ExpandEnvironmentVariables($selectedWebSite.physicalPath) 

	$connectionString = Join-Path -Path $physicalPath -ChildPath "App_Config\connectionstrings.config"

    $parameters = @{
        'SiteName'     = $selectedWebSite.name
        'AppPoolName'  = $selectedWebSite.applicationPool
        
		'SqlServerName'= Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Web  -ParameterName "Data Source"
        'SqlUser'      = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Web  -ParameterName "user id"
        
		'Sitecore.Root' = Split-Path -Path $physicalPath -Parent

        'Sql.Database.Web' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Web  -ParameterName "Database"
        'Sql.Database.Core' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Core  -ParameterName "Database"
        'Sql.Database.Master' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Master  -ParameterName "Database"
        'Sql.Database.Analytics' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Reporting  -ParameterName "Database"
		'Sql.Database.Sessions' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName Sessions  -ParameterName "Database"
        
		'Mongo.Analytics' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName 'analytics'  -ParameterName "connectionstring"
        'Mongo.Tracking.Live' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName 'tracking.live'  -ParameterName "connectionstring"
        'Mongo.Tracking.History' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName 'tracking.history'  -ParameterName "connectionstring"
        'Mongo.Tracking.Contact' = Invoke-GetConnectionStringElementConfigFunction -ConnectionStringsPath $connectionString -ConnectionStringName 'tracking.contact'  -ParameterName "connectionstring"
    }

	$isConfirmed = ($parameters | Out-GridView -Title "Please confirm resources to remove" -OutputMode Single )

	if( $null -eq $isConfirmed )
	{	
		Write-Verbose "User do not confirm remove action"
		return @{}
	}

    return $parameters
}

Export-ModuleMember Select-WebSite

