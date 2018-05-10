function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Install-FromWeb {
    param(
		[Parameter(Mandatory=$true)]
		[string]$Url,
		[Parameter(Mandatory=$true)]
		[string]$Args
	)
    $Path = $env:TEMP; 
    $Installer = "installer.exe"; 
    Invoke-WebRequest $Url -OutFile $Path\$Installer; 
    Start-Process -FilePath $Path\$Installer -Args $Args -Verb RunAs -Wait; 
    Remove-Item $Path\$Installer
}

Disable-ieESC
Install-FromWeb -Url "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -Args "/silent /install"

Install-FromWeb -Url "https://notepad-plus-plus.org/repository/7.x/7.5.6/npp.7.5.6.Installer.x64.exe" -Args "/S"

#https://github.com/git-for-windows/git/releases/download/v2.17.0.windows.1/Git-2.17.0-64-bit.exe

