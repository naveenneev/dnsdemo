//
//  VPN.swift
//  NetworkDemo
//
//  Created by Aeologic on 12/07/21.
//

import Foundation
import NetworkExtension

class VPN
{
    let vpnManager = NEVPNManager.shared();
    
    private var vpnLoadHandler: (Error?) -> Void { return
        { (error:Error?) in
            
            if ((error) != nil)
            {
                print("Could not load VPN Configurations : \(error?.localizedDescription ?? "Unknown reason")");
                return;
            }
            let p = NEVPNProtocolIPSec() // NEVPNProtocolIKEv2() // NEVPNProtocolIPSec()
            
            p.username = "ScreenCoach"
            p.serverAddress = "192.168.43.64"//"192.168.0.105"
            
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
            
            let kcs = KeychainService();
            kcs.save(key: "SHARED", value: "ScreenCoachKey")
            kcs.save(key: "VPN_PASSWORD", value: "rootuser")
            p.sharedSecretReference = kcs.load(key: "SHARED")
            p.passwordReference = kcs.load(key: "VPN_PASSWORD")
            p.useExtendedAuthentication = true
            p.disconnectOnSleep = false
            
            
            self.vpnManager.protocolConfiguration = p
            self.vpnManager.localizedDescription = "ScreenCoach"
            self.vpnManager.isEnabled = true
            
            let evaluationRule = NEEvaluateConnectionRule(matchDomains: TLDList.tlds, andAction: .connectIfNeeded)
            evaluationRule.useDNSServers = ["185.228.168.90", "185.228.169.90"]
            
           
            let onDemandRule = NEOnDemandRuleEvaluateConnection()
            onDemandRule.connectionRules = [evaluationRule]
            onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.any
           
            self.vpnManager.onDemandRules = [onDemandRule]
            self.vpnManager.isOnDemandEnabled = true
            self.vpnManager.isEnabled = true
            
            self.vpnManager.saveToPreferences(completionHandler: self.vpnSaveHandler)
            
        }
        
    }
    
    private var vpnSaveHandler: (Error?) -> Void { return
        { (error:Error?) in
            if (error != nil) {
                print("Could not save VPN Configurations")
                return
            } else {
                do {
                    try self.vpnManager.connection.startVPNTunnel()
                } catch let error {
                    print("Error starting VPN Connection \(error.localizedDescription)");
                }
            }
        }
        //            self.vpnlock = false
        
    }



    public func connectVPN()
    {
        //For no known reason the process of saving/loading the VPN configurations fails.On the 2nd time it works
        vpnManager.loadFromPreferences(completionHandler: self.vpnLoadHandler);
    }


    public func disconnectVPN() ->Void
    {
        vpnManager.connection.stopVPNTunnel()
    }


}
