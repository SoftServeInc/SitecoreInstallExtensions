<%@ WebService Language="C#" Class="PackageInstaller" %>
using System;
using System.Configuration;
using System.IO;
using System.Web.Services;
using System.Xml;
using Sitecore.Data.Proxies;
using Sitecore.Data.Engines;
using Sitecore.Install.Files;
using Sitecore.Install.Framework;
using Sitecore.Install.Items;
using Sitecore.SecurityModel;
using Sitecore.Update;
using Sitecore.Update.Installer;
using Sitecore.Update.Installer.Utils;
using Sitecore.Update.Utils;
using log4net;
using log4net.Config;

/// <summary>
/// Summary description for UpdatePackageInstaller
/// </summary>
[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[System.ComponentModel.ToolboxItem(false)]
// To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
// [System.Web.Script.Services.ScriptService]
public class PackageInstaller : System.Web.Services.WebService
{
  /// <summary>
  /// Installs a Sitecore Update Package.
  /// </summary>
  /// <param name="path">A path to a package that is reachable by the web server</param>
  [WebMethod(Description = "Installs a Sitecore Update Package.")]
  public void InstallUpdatePackage(string path)
  {
    // Use default logger
    var log = LogManager.GetLogger("root");
    XmlConfigurator.Configure((XmlElement)ConfigurationManager.GetSection("log4net"));

    var file = new FileInfo(path);  
    if (!file.Exists)  
      throw new ApplicationException(string.Format("Cannot access path '{0}'.", path)); 
        
    using (new SecurityDisabler())
    {
      var installer = new DiffInstaller(UpgradeAction.Upgrade);
      var view = UpdateHelper.LoadMetadata(path);

      //Get the package entries
      bool hasPostAction;
      string historyPath;
      var entries = installer.InstallPackage(path, InstallMode.Install, log, out hasPostAction, out historyPath);

      installer.ExecutePostInstallationInstructions(path, historyPath, InstallMode.Install, view, log, ref entries);

      UpdateHelper.SaveInstallationMessages(entries, historyPath);
    }
  }
	
  /// <summary>
  /// Installs a Sitecore Zip Package.
  /// </summary>
  /// <param name="path">A path to a package that is reachable by the web server</param>
  [WebMethod(Description = "Installs a Sitecore Zip Package.")]
  public void InstallZipPackage(string path)
  {
    // Use default logger
    var log = LogManager.GetLogger("root");
    XmlConfigurator.Configure((XmlElement)ConfigurationManager.GetSection("log4net"));

    var file = new FileInfo(path);  
    if (!file.Exists)  
      throw new ApplicationException(string.Format("Cannot access path '{0}'.", path)); 
		
    Sitecore.Context.SetActiveSite("shell");  
    using (new SecurityDisabler())  
    {  
      using (new ProxyDisabler())  
      {  
        using (new SyncOperationContext())  
        {  
          IProcessingContext context = new SimpleProcessingContext(); //   
          IItemInstallerEvents events =  
            new DefaultItemInstallerEvents(new Sitecore.Install.Utils.BehaviourOptions(Sitecore.Install.Utils.InstallMode.Overwrite, Sitecore.Install.Utils.MergeMode.Undefined));  
          context.AddAspect(events);  
          IFileInstallerEvents events1 = new DefaultFileInstallerEvents(true);  
          context.AddAspect(events1);  
          var installer = new Sitecore.Install.Installer();  
          installer.InstallPackage(Sitecore.MainUtil.MapPath(path), context);  
        }  
      }  
    }  
  }
}