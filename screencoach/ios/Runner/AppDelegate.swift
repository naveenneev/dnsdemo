import UIKit
import Flutter
import Firebase
import NetworkExtension

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool
    {
    
        GeneratedPluginRegistrant.register(with: self)
        
        FirebaseApp.initialize();
        if FirebaseApp.app() == nil
        {
            FirebaseApp.configure()
        }
        
        let resolver =  DNSLookup.init();
        let allDNS = resolver.getDNSAddressesCSV();
        print("Got all DNS = \(allDNS)");
        
        if let lookUp = resolver.resolveHost("www.apple.com", withDomain: "8.8.8.8") {
            print("Lookup = \(lookUp)");
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
}
