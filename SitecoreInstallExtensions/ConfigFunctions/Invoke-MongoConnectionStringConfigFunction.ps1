#
# Invoke_MongoConnectionStringFunction.ps1
# https://docs.mongodb.com/manual/reference/connection-string/
#
# mongodb://[username:password@]host1[:port1]/[database]
# mongodb://localhost:27017/Sitecore_tracking_live
         
function Invoke-MongoConnectionStringConfigFunction {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams','')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ServerName,
        [AllowEmptyString()]
        [AllowNull()]
        [string]$ServerPort,
        [AllowEmptyString()]
        [AllowNull()]
        [string]$DatabaseName,
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Options,
        [AllowEmptyString()]
        [AllowNull()]
        [string]$UserName,
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Password
    )

    Write-Verbose -Message $PSCmdlet.MyInvocation.MyCommand
  
    $connectionStringBuilder = New-Object -TypeName "System.Text.StringBuilder"

    [void]$connectionStringBuilder.Append("mongodb://")

    if ($UserName -and $Password){
        [void]$connectionStringBuilder.Append($UserName)
        [void]$connectionStringBuilder.Append(":")
        [void]$connectionStringBuilder.Append($Password)
        [void]$connectionStringBuilder.Append("@")
    }

    [void]$connectionStringBuilder.Append($ServerName)

    if ($ServerPort){
        [void]$connectionStringBuilder.Append(":")
        [void]$connectionStringBuilder.Append($ServerPort)
    }

    [void]$connectionStringBuilder.Append("/")
    [void]$connectionStringBuilder.Append($DatabaseName)

    if ($Options) {
        [void]$connectionStringBuilder.Append("?")
        [void]$connectionStringBuilder.Append($Options)
    }

    $result = $connectionStringBuilder.ToString()

    Write-Verbose "Result: $result"
    return $result
}

Export-ModuleMember Invoke-MongoConnectionStringConfigFunction
