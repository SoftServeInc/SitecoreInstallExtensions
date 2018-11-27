#
# Invoke-DownloadSitecoreFile.ps1
#
Function Invoke-DownloadSitecoreFile {
<#
.SYNOPSIS
	Download specified file from Sitecore download site.	

.DESCRIPTION
	The Invoke-DownloadSitecoreFile is registered as DownloadSitecoreFile type.

.EXAMPLE
	Json task configuration for Sitecore Install Framework:

	"DownloadFile": {
      "Type": "DownloadSitecoreFile",
      "Params": {
		  "UserName" : "",
		  "Password" : "",
		  "SourceUri" : "",
		  "DestinationFolder" : "",
      }
    }


.EXAMPLE
		Invoke-DownloadSitecoreFile -UserName 'your@email.com' -Password 'yourPassword' -SourceUri 'https://dev.sitecore.net/~/media/F97AEBC82D2A4EFFBED9C95EC5E9DC31.ashx' -DestinationFolder "C:\\SitecoreFiles

#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	param(
		[Parameter(Mandatory=$true)]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[string]$Password,
		[Parameter(Mandatory=$true)]
		[string]$SourceUri,
		[Parameter(Mandatory=$true)]
		[string]$DestinationFolder,
		[Parameter(Mandatory=$false)]
		[string]$SitecoreAuthorizationUrl = "https://dev.sitecore.net/api/authorization"
	)

	if($pscmdlet.ShouldProcess($SourceUri, "Execute download Sitecore File"))
    {
		$params = @{
			Uri = "$SitecoreAuthorizationUrl"
			Method = "Post"
			ContentType = "application/json"
			Body = "{ username: ""$UserName"", password: ""$Password""}" 
		}

		try
		{
			$response = Invoke-RestMethod -SessionVariable Session -UseBasicParsing @params 

			if( $response -eq 'True' )
			{
				$head =  Invoke-WebRequest -Method Head -Uri $SourceUri -WebSession $session
				$head.Headers['Content-Disposition'] -match "\w+;\s+filename=(?<filename>.*)" | Out-Null

				$fileName = $matches['filename'] -replace '"'
		
		
				Write-Verbose "Download from $SourceUri to $DestinationFolder\$fileName"
				Invoke-WebRequest -Uri $SourceUri -WebSession $session -UseBasicParsing -OutFile (Join-Path -Path $DestinationFolder -ChildPath $fileName) 
	
			}
			else
			{
				Write-Warning "Authentication error"
			}
		}
		catch
		{
			Write-Warning $_.Exception 
		}
	}
}

Export-ModuleMember Invoke-DownloadSitecoreFile
Register-SitecoreInstallExtension -Command Invoke-DownloadSitecoreFile -As DownloadSitecoreFile -Type Task


