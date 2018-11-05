#requires -RunAsAdministrator 

Write-Host "SQL" -ForegroundColor Green
Get-Service *SQL*

Write-Host "SOLR" -ForegroundColor Green
Get-Service *solr* 
(gwmi win32_service|?{$_.name -like "*solr*"}).pathname

Write-Host "Mongo" -ForegroundColor Green
Get-Service *mongo*
(gwmi win32_service|?{$_.name -like "*mongo*"}).pathname

Write-Host "xConnect" -ForegroundColor Green
Get-Service -DisplayName *sitecore*
(gwmi win32_service|?{$_.displayname -like "*sitecore*"}).pathname


Write-Host "Sitecore websites" -ForegroundColor Green
Get-WebSite | ForEach-Object { 
    
    $binPath = Join-Path -Path $_.PhysicalPath -ChildPath "bin\Sitecore.Kernel.dll" 
    $item = Get-Item -Path $binPath -ErrorAction SilentlyContinue

    if( $item -ne $null )
    {
        "Sitecore Site: Name:$($_.Name), Version: $($item.VersionInfo.FileVersion), Path  $($_.PhysicalPath)" 
    }
}

Write-Host "Environment Variables" -ForegroundColor Green
[environment]::GetEnvironmentVariable("JAVA_HOME")
[environment]::GetEnvironmentVariable("SOLR_HOME")




