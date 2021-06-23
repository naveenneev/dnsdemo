import UIKit
import Flutter
import Firebase
import NetworkExtension

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
        let connect = VPNConnect.init();
        connect.connected = true;
    }
    
//    setDNS(dns: "8.8.4.4");
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    
    
    func setDNS(dns: String)
    {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { error in
            if let vpnError = error {
                print("vpn error in loading preferences : \(vpnError)")
                return
            }
           
            if manager.protocolConfiguration == nil {
                let myIPSec = NEVPNProtocolIPSec()
                myIPSec.username = "username"
                myIPSec.serverAddress = "server address"
//                myIPSec.passwordReference = self.getPersistentRef()
                myIPSec.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
//                myIPSec.sharedSecretReference = self.getPersistentRef()
                myIPSec.useExtendedAuthentication = true
               
                manager.protocolConfiguration = myIPSec
                manager.localizedDescription = "ScreenCoach"
               
                let evaluationRule = NEEvaluateConnectionRule(matchDomains: ["*.com"], andAction: NEEvaluateConnectionRuleAction.connectIfNeeded)
                evaluationRule.useDNSServers = [dns]
               
                let onDemandRule = NEOnDemandRuleEvaluateConnection()
                onDemandRule.connectionRules = [evaluationRule]
                onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.any
               
                manager.onDemandRules = [onDemandRule]
                manager.isOnDemandEnabled = true
                manager.isEnabled = true
               
                manager.saveToPreferences { error in
                    if let vpnError = error {
                        print("vpn error in saving preferences : \(vpnError)")
                        return
                    }
                }
            }
        }
    }
    
}
