//
//  DNSLookup.h
//  Runner
//
//  Created by Aeologic on 18/06/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DNSLookup : NSObject


/// Following method will resolve the host for a given DNS server to check if DNS is working or not
- (NSString *)resolveHost:(NSString *)host usingDNSServer:(NSString *)dnsServer;

/// Resolve host using a specified domain while initialising
- (nullable NSArray<NSString *> *)resolveHost:(nonnull NSString *)host withDomain:(nonnull NSString*)domain;


/// Following method is to fetch the list of DNS configured in your device.
- (NSString *)getDNSAddressesCSV;
@end

NS_ASSUME_NONNULL_END
