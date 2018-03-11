# Sitecore Install Extensions (SIX)
A Powershell module with extensions for Sitecore Install Framework. The introduction to Sitecore Install Framework is available on [Youtube](https://youtu.be/syslVshavOw)

## With SIX module we are able to install:
* Sitecore prerequisites like JRE, MongoDb, Solr [An example configuration to install prerequisites](Configuration/sitecore-prerequisites.json)
* Configure Solr as a Windows service without any dependence [Details on blog](http://lets-share.senktas.net/2017/11/solr-as-a-service.html)
* Install Sitecore 8+ in a SIF manner [An example configuration to install Sitecore 8 Update 6](Configuration/sitecore8-xp0.json)
* Install Sitecore modules [An example configuration to install WFFM, SPE and SXA](Configuration/sitecore-packages.json)
* Uninstall Sitecore [An example configuration to uninstall Sitecore](Configuration/remove-sitecore8-xp0.json)

> Remember to configure installation process regarding to your requirements.

# How to start?
To start work with Sitecore Install Extensions you have to install or update the following modules:
* Sitecore Install Framework
* Sitecore Fundamentals
* Sitecore Install Extensions
* Sitecore Install Azure

You can do this manually or just run script [install-modules.ps1](install-modules.ps1). This script will install or update required modules automatically.

# Tasks & Config Functions

Tasks are actions that are conducted in sequence when the Install-SitecoreConfiguration cmdlet
is called. A task is implemented as a PowerShell cmdlet.
Each task is identified by a unique name and must contain a Type property. 

Config functions allow elements of the configuration to be dynamic, letting you calculate values, invoke
functions, and pass these values to tasks so that a configuration can be flexible.

[List of tasks and config functions implemented by Sitecore Install Extensions](https://github.com/SoftServeInc/SitecoreInstallExtensions/blob/master/Documentation/readme.md)

# Examples


# Roadmap


# SoftServe
Thanks to [SoftServe](https://www.softserveinc.com/en-US/) sponsorship Sitecore Install Experience modul will be open for public access for Sitecore Community attendees.
Softserve is a global leader in IT services and has offices around the world delivering tailored tech solutions for various branches and business sectors.


