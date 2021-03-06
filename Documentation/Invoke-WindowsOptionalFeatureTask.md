> This file is autogenerated please update doc in Powershell files
# Invoke-WindowsOptionalFeatureTask 
 
Installs one or more roles, role services, or features on the workstation 
 
## Syntax 
 
Invoke-WindowsOptionalFeatureTask [[-FeaturesToInstall] &lt;String[]&gt;] [-WhatIf] [-Confirm] 
 
 
## Detailed Description 
 
The Invoke-WindowsOptionalFeatureTask is registered as WindowsOptionalFeature type. 
 
## Parameters 
 
### -FeaturesToInstall&nbsp; &lt;String[]&gt; 
 
 
 
<table>
    <thead></thead>
    <tbody>
        <tr>
            <td>Aliases</td>
            <td></td>
        </tr>
        <tr>
            <td>Required?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Position?</td>
            <td>1</td>
        </tr>
        <tr>
            <td>Default Value</td>
            <td></td>
        </tr>
        <tr>
            <td>Accept Pipeline Input?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Accept Wildcard Characters?</td>
            <td>false</td>
        </tr>
    </tbody>
</table> 
 
### -WhatIf&nbsp; &lt;SwitchParameter&gt; 
 
 
 
<table>
    <thead></thead>
    <tbody>
        <tr>
            <td>Aliases</td>
            <td></td>
        </tr>
        <tr>
            <td>Required?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Position?</td>
            <td>named</td>
        </tr>
        <tr>
            <td>Default Value</td>
            <td></td>
        </tr>
        <tr>
            <td>Accept Pipeline Input?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Accept Wildcard Characters?</td>
            <td>false</td>
        </tr>
    </tbody>
</table> 
 
### -Confirm&nbsp; &lt;SwitchParameter&gt; 
 
 
 
<table>
    <thead></thead>
    <tbody>
        <tr>
            <td>Aliases</td>
            <td></td>
        </tr>
        <tr>
            <td>Required?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Position?</td>
            <td>named</td>
        </tr>
        <tr>
            <td>Default Value</td>
            <td></td>
        </tr>
        <tr>
            <td>Accept Pipeline Input?</td>
            <td>false</td>
        </tr>
        <tr>
            <td>Accept Wildcard Characters?</td>
            <td>false</td>
        </tr>
    </tbody>
</table> 
 
## Examples 
 
### EXAMPLE 1 
 
Json task configuration for Sitecore Install Framework: 
 
```powershell   
 
"InstallRequiredFeatures": {
     "Type": "WindowsOptionalFeature",
     "Params": {
       "FeaturesToInstall":  [
		"IIS-ASPNET45",
		"IIS-WebServer"
	  ]
     }
   }
) 
 
``` 
 
### EXAMPLE 2 
 
Invoke-WindowsOptionalFeatureTask -FeaturesToInstall $windowsFeatures 
 
```powershell   
 
$windowsFeatures = @('IIS-ASPNET45' ) 
 
``` 
 

