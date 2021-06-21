//
//  DNSLookup.m
//  Runner
//
//  Created by Aeologic on 18/06/21.
//

#import "DNSLookup.h"
#include <resolv.h>
#include <netdb.h>
#include <arpa/inet.h>

struct __res_state_ext {
    union res_sockaddr_union nsaddrs[MAXNS];
    struct sort_list {
        int af;
        union {
            struct in_addr  ina;
            struct in6_addr in6a;
        } addr, mask;
    } sort_list[MAXRESOLVSORT];
    char nsuffix[64];
    char bsuffix[64];
    char nsuffix2[64];
};



@implementation  DNSLookup {
    res_state _state;
}



- (instancetype)init {
    self = [super init];
    if (self) {
        _state = malloc(sizeof(struct __res_state));
        if (EXIT_SUCCESS != res_ninit(_state)) {
            free(_state);
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    res_ndestroy(_state);
    free(_state);
}


- (BOOL)setDNSServer:(nonnull NSString *)server
{
    // man 3 resolver:
    //
    // The memory referred to by statp must be set to all zeros prior
    // to the first call to res_ninit(). res_ndestroy() should be call to free memory
    // allocated by res_ninit() after last use.
    if ((_state = calloc(1, sizeof(*_state))) == NULL) {
        return NO;
    }

    // 0 success
    if (res_ninit(_state) != 0) {
        return NO;
    }

    // Avoid calling inet_aton later with NULL if we can't convert it to ASCII
    if (![server canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        return NO;
    }

    struct in_addr addr;

    // man 3 inet_aton:
    //
    // It returns 1 if the string was successfully interpreted ...
    if (inet_aton([server cStringUsingEncoding:NSASCIIStringEncoding], &addr) != 1) {
        return NO;
    }

    _state->nsaddr_list[0].sin_addr = addr;
    _state->nsaddr_list[0].sin_family = AF_INET;
    _state->nsaddr_list[0].sin_port = htons(NS_DEFAULTPORT);
    _state->nscount = 1;

    return YES;
}

- (nullable NSArray<NSString *> *)resolveHost:(nonnull NSString *)host withDomain:(nonnull NSString*)domain {
    
    BOOL success = [self setDNSServer:domain];
    
    if(!success){
        return nil;
    }
    
    
    // Avoid calling res_nquery with NULL
    if (![host canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        return nil;
    }

    u_char answer[NS_PACKETSZ];

    int len = res_nquery(_state, [host cStringUsingEncoding:NSASCIIStringEncoding],
                         ns_c_in, ns_t_a, answer, sizeof(answer));

    // -1 = error
    if (len == -1) {
        return nil;
    }

    ns_msg handle;

    // 0 success, -1 error
    if (ns_initparse(answer, len, &handle) != 0) {
        return nil;
    }

    u_int16_t count = ns_msg_count(handle, ns_s_an);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0 ; i < count ; i++) {
        ns_rr rr;
        // 0 success, -1 error
        if (ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
            char *address = inet_ntoa(*(struct in_addr *)ns_rr_rdata(rr));

            if (address == NULL) {
                continue;
            }

            NSString *ip = [NSString stringWithCString:address
                                              encoding:NSASCIIStringEncoding];
            [result addObject:ip];
        }
    }

    return result;
}



#pragma mark -------------------------- PUBLIC METHODS

- (NSString *)getDNSAddressesCSV
{
    NSMutableArray *addresses = [NSMutableArray new];

    union res_sockaddr_union servers[NI_MAXSERV];

    int serversFound = res_9_getservers(_state, servers, NI_MAXSERV);

    char hostBuffer[NI_MAXHOST];
    for (int i = 0; i < serversFound; i ++) {
        union res_sockaddr_union s = servers[i];
        if (s.sin.sin_len > 0) {
            if (EXIT_SUCCESS == getnameinfo((struct sockaddr *)&s.sin,  // Pointer to your struct sockaddr
                                            (socklen_t)s.sin.sin_len,   // Size of this struct
                                            (char *)&hostBuffer,        // Pointer to hostname string
                                            sizeof(hostBuffer),         // Size of this string
                                            nil,                        // Pointer to service name string
                                            0,                          // Size of this string
                                            NI_NUMERICHOST)) {          // Flags given
                [addresses addObject:[NSString stringWithUTF8String:hostBuffer]];
            }
        }
    }

    return [addresses componentsJoinedByString:@","];
}


- (NSString *)resolveHost:(NSString *)host usingDNSServer:(NSString *)dnsServer
{
    struct __res_state res;
    char ip[INET6_ADDRSTRLEN];
    memset(ip, '\0', sizeof(ip));

    res_ninit(&res);
    setup_dns_server(&res, [dnsServer cStringUsingEncoding:NSASCIIStringEncoding]);
    query_ip(&res, [host cStringUsingEncoding:NSUTF8StringEncoding], ip);
    res_ndestroy(&res);

    return [[NSString alloc] initWithCString:ip encoding:NSASCIIStringEncoding];
}


#pragma mark --------------------- PRIVATE METHODS

void query_ip(res_state res, const char *host, char ip[])
{
    u_char answer[NS_PACKETSZ];
    int len = res_nquery(res, host, ns_c_in, ns_t_aaaa, answer, sizeof(answer));

    ns_msg handle;
    ns_initparse(answer, len, &handle);


    if(ns_msg_count(handle, ns_s_an) > 0) {
        ns_rr rr;
        if(ns_parserr(&handle, ns_s_an, 0, &rr) == 0) {
            inet_ntop(AF_INET6, ns_rr_rdata(rr), ip, INET6_ADDRSTRLEN);
        }
    }
}


void setup_dns_server(res_state res, const char *dns_server)
{
    struct in6_addr addr;

    inet_pton(AF_INET6, dns_server, &addr);

    res->_u._ext.ext->nsaddrs[0].sin6.sin6_addr = addr;
    res->_u._ext.ext->nsaddrs[0].sin6.sin6_family = AF_INET6;
    res->_u._ext.ext->nsaddrs[0].sin6.sin6_port = htons(NS_DEFAULTPORT);
    res->nscount = 1;
}


@end
