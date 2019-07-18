
<#
.SYNOPSIS
 Login to a Sitecore Download page

.DESCRIPTION
 Connect-ToSitecore function creates a session object when user authorization will finish with success, otherwise returns $null.

.PARAMETER UserName

.PARAMETER Password
#>
function Connect-ToSitecore {
    [CmdletBinding()]
    param (
        [string] $UserName,
        [string] $Password    
    )
    
    $params = @{
        Uri         = "https://dev.sitecore.net/api/authorization"
        Method      = "Post"
        Contenttype = "application/json"
        Body        = "{ username: '$UserName', password: '$Password'}"
    }
    
    
    $status = Invoke-RestMethod -SessionVariable session -UseBasicParsing @params
    
    if ( $status -eq $false ) {
        Write-Warning "Authentication failed"
        return $null
    }
    
    return $session
}

<#
.SYNOPSIS
    Parse Sitecore page
.DESCRIPTION
    Read-SitecorePage parses a page content and provides a list of files available to download.

.NOTES
    Read-SitecorePage requires to call Connect-ToSitecore first.
#>

function Read-SitecorePage {
    param (
        [string] $UrlToParse,
        [Microsoft.PowerShell.Commands.WebRequestSession] $Session
    )
    
    $content = Invoke-WebRequest -Method Get -Uri $UrlToParse -WebSession $Session
    
    return $content.Links | Where-Object { $null -ne $_.'downloads-file' } | ForEach-Object {

        $uri = $($_.href)
    
        if ( $uri -match "media" ) {
            if ( $uri -notmatch "https://dev.sitecore.net" ) {
                $uri = "https://dev.sitecore.net$uri"
            }

            #Write-Host "Processing $uri"

            $head = Invoke-WebRequest -Method Head -Uri $uri -WebSession $session
            if ( $null -ne $head ) {
                # Get filename from header   
                $head.Headers['Content-Disposition'] -match "\w+;\s+filename=(?<filename>.*)" | Out-Null
                $outFile = $matches['filename'] -replace '"'

                #Write-Output "$($_.href) is translated to $outFile"
                $data = [pscustomobject]@{
                    FileName = $outFile
                    Url      = $uri
                }        
            
                return $data   
            }
        }

    }
}



function Get-SitecoreFiles {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $pipelineInput,
        [string] $Destination,
        [Microsoft.PowerShell.Commands.WebRequestSession] $Session
    )
    
    process {
        $pipelineInput | ForEach-Object {
            $outFile = Join-Path -Path $Destination -ChildPath $_.FileName
            $url = $_.Url
            Write-Output "Download file $($_.FileName) to $outFile"
            
            Invoke-WebRequest -Uri $url -WebSession $Session -UseBasicParsing -OutFile $outFile
        } 
    }
}


$credentials = @{
    userName = ''
    password = ''
}

# Sitecore page to parse
$download = "https://dev.sitecore.net/Downloads/Sitecore_Experience_Platform/91/Sitecore_Experience_Platform_91_Update1.aspx"

# Folder name where Sitecore files will be downloaded
$destination = "C:\SitecoreInstall\Sitecore_Experience_Platform_91_Update1"
mkdir $destination -force | Out-Null

$session = Connect-ToSitecore -UserName $credentials.userName -Password $credentials.password

$filesToDownload = Read-SitecorePage -UrlToParse $download -Session $session 

$selectedFiles = $filesToDownload | Out-GridView -Title "Choose Sitecore packages to download" -OutputMode Multiple

$selectedFiles | Get-SitecoreFiles -Destination $destination -Session $session

