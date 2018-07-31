# Sitecore Install Extensions (SIX) 
A Powershell module with extensions for Sitecore Install Framework. The introduction to Sitecore Install Framework is available on [Youtube](https://youtu.be/syslVshavOw)

| Module | Downloads |  Version |
|---|---|---|
| Sitecore Install Extensions | [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/sitecoreinstallextensions.svg?style=flat-square)](https://www.powershellgallery.com/packages/sitecoreinstallextensions)| [![powershellgallery](https://img.shields.io/powershellgallery/v/sitecoreinstallextensions.svg?style=flat-square)](https://www.powershellgallery.com/packages/sitecoreinstallextensions) |
| Sitecore Install Azure | [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/sitecoreinstallazure.svg?style=flat-square)](https://www.powershellgallery.com/packages/sitecoreinstallazure) | [![powershellgallery](https://img.shields.io/powershellgallery/v/sitecoreinstallazure.svg?style=flat-square)](https://www.powershellgallery.com/packages/sitecoreinstallazure) |

# How to start?
To start work with Sitecore Install Extensions you have to run this snippet with _Administrator_ rights.

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force;
iex ((New-Object System.Net.WebClient).DownloadString('http://bit.ly/installmodules'))
```

The script above download install or update the following modules:
Sitecore Install Framework, Sitecore Fundamentals, [Sitecore Install Extensions](https://www.powershellgallery.com/packages/sitecoreinstallextensions), [Sitecore Install Azure](https://www.powershellgallery.com/packages/SitecoreInstallAzure)

You can install modues manually or just run script [install-modules.ps1](install-modules.ps1).

## Features
[Very Short Introduction to SIX module on Youtube](https://youtu.be/-u2BGO6yM-w)

* Sitecore prerequisites like JRE, MongoDb, Solr [An example configuration to install prerequisites](Configuration/sitecore-prerequisites.json)
* Configure Solr as a Windows service without any dependence [Details on blog](http://lets-share.senktas.net/2017/11/solr-as-a-service.html)
* Install Sitecore 8+ in a SIF manner [An example configuration to install Sitecore 8 Update 6](Configuration/sitecore8-xp0.json)
* Install Sitecore modules [An example configuration to install WFFM, SPE and SXA](Configuration/sitecore-packages.json)
* Uninstall Sitecore [An example configuration to uninstall Sitecore](Configuration/remove-sitecore8-xp0.json)

> Remember to configure installation process regarding to your requirements.

## Examples
[The bigest how to collection about Sitecore Installation Framework and Sitecore Install Extensions is wiki](https://github.com/SoftServeInc/SitecoreInstallExtensions/wiki)


# Tasks & Config Functions

Tasks are actions that are conducted in sequence when the Install-SitecoreConfiguration cmdlet
is called. A task is implemented as a PowerShell cmdlet.
Each task is identified by a unique name and must contain a Type property. 

Config functions allow elements of the configuration to be dynamic, letting you calculate values, invoke
functions, and pass these values to tasks so that a configuration can be flexible.

[List of tasks and config functions implemented by Sitecore Install Extensions](https://github.com/SoftServeInc/SitecoreInstallExtensions/blob/master/Documentation/readme.md)

# Examples

> Remember to configure installation process regarding to your requirements and needs.

SIX module comes with examples how to use tasks, and config functions are part of SIX.
The script *[install-all-example.ps1](install-all-example.ps1)* contains the four steps:
* Download all required files from Azure Storage **([of course you have to build your storage](http://lets-share.senktas.net/2017/09/sitecore-on-azure-storagepreparation.html))**
* Install Sitecore 8 prerequisites like MongoDB, Solr, RoboMongo
* Install Sitecore 8 update 6
* Install Sitecore modules Sitecore Powershell Extension, Sitecore Experience Accelerator, Web Forms For Marketers

> Remember to configure installation process regarding your requirements and needs.

Time to time, we want to uninstall Sitecore and here *[uninstall-sitecore.ps1](uninstall-sitecore.ps1)* the script will come with help.

# Roadmap
* Merge with other Sitecore community Powershell scripts to provide valuable module in one place
* Add documentation and examples to every function
* Connect solution to [Pester](https://github.com/pester/Pester)
* Connect solution to [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)

# SoftServe
Thanks to [SoftServe](https://www.softserveinc.com/en-US/) sponsorship initial version of Sitecore Install Extensions modul will be open for public access for Sitecore Community attendees.
Softserve is a global leader in IT services and has offices around the world delivering tailored tech solutions for various branches and business sectors.

# Bitly
A few handy short links are configured:

http://bit.ly/git-six redirect to https://github.com/SoftServeInc/SitecoreInstallExtensions

http://bit.ly/installmodules redirect to https://raw.githubusercontent.com/SoftServeInc/SitecoreInstallExtensions/master/install-modules.ps1

http://bit.ly/six-wiki redirects to https://github.com/SoftServeInc/SitecoreInstallExtensions/wiki

