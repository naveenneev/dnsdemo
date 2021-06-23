//
//  File.swift
//  Runner
//
//  Created by Aeologic on 23/06/21.
//

import Foundation
import NetworkExtension

// my Device config
// 145.249.106.12
// 8.8.4.4

public class VPNConnect {
    private static let vpnDescription = "Screen Coach"
    private static let vpnServerDescription = "atl1.gpvpn.com"

    public var manager:NETunnelProviderManager = NETunnelProviderManager()
    public var dnsEndpoint1:String = "1.0.0.1"
    public var dnsEndpoint2:String = "149.112.112.112"

    public var connected:Bool {
        get {
            return self.manager.isOnDemandEnabled
        }
        set {
            if newValue != self.connected {
                update(
                    body: {
                        self.manager.isEnabled = newValue
                        self.manager.isOnDemandEnabled = newValue

                    },
                    complete: {
                        if newValue {
                            do {
                                try (self.manager.connection as? NETunnelProviderSession)?.startVPNTunnel(options: nil)
                            } catch let err as NSError {
                                NSLog("\(err.localizedDescription)")
                            }
                        } else {
                            (self.manager.connection as? NETunnelProviderSession)?.stopVPNTunnel()
                        }
                    }
                )
            }
        }
    }

    public init() {
        refreshManager()
    }

    public func refreshManager() -> Void {
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { (managers, error) in
            if nil == error {
                if let managers = managers {
                    for manager in managers {
                        if manager.localizedDescription == VPNConnect.vpnDescription {
                            self.manager = manager
                            return
                        }
                    }
                }
            }
            self.setPreferences()
        })
    }

    private func update(body: @escaping ()->Void, complete: @escaping ()->Void)
    {
        manager.loadFromPreferences { error in
            if (error != nil) {
                NSLog("Load error: \(String(describing: error?.localizedDescription))")
                return
            }
            body()

            self.manager.saveToPreferences { (error) in
                if nil != error {
                    NSLog("vpn_connect: save error \(error!)");

                    // ------- Saving Twice if error

                    self.manager.saveToPreferences { (error) in
                        if nil != error {
                            NSLog("vpn_connect: save error again :  \(error!)");

                        } else {
                            complete()
                        }
                    }

                    // ---- END OF SAVING TWICE

                } else {
                    complete()
                }
            }
        }
        
        
//        self.manager.saveToPreferences { (error) in
//            if nil != error {
//                NSLog("save Preference error: save error \(error!)");
//            }
//
//            body();
//
//            self.manager.loadFromPreferences { error in
//                if nil != error
//                {
//                    NSLog("load Preference: save error \(error!)");
//                }
//                else
//                {
//                    complete()
//                }
//            }
//
//        }
    }

    private func setPreferences() {
        self.manager.localizedDescription = VPNConnect.vpnDescription
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "demo.app.screencoach"
        proto.serverAddress = VPNConnect.vpnServerDescription
        self.manager.protocolConfiguration = proto
        // TLDList is a struct I created in its own swift file that has an array of all top level domains
        let evaluationRule = NEEvaluateConnectionRule(matchDomains: TLDList.tlds,
                                                         andAction: NEEvaluateConnectionRuleAction.connectIfNeeded)
        evaluationRule.useDNSServers = [self.dnsEndpoint1, self.dnsEndpoint2]
        let onDemandRule = NEOnDemandRuleEvaluateConnection()
        onDemandRule.connectionRules = [evaluationRule]
        onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.any
        self.manager.onDemandRules = [onDemandRule]
    }
}
