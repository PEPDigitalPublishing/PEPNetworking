//
//  PEPNetworkReachabilityManager.m
//  AFNetworking
//
//  Created by Karl on 2018/2/28.
//

#import "PEPNetworkReachabilityManager.h"
#import <AFNetworking/AFNetworking.h>

@implementation PEPNetworkReachabilityManager

+ (instancetype)sharedManager{
    static PEPNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}


- (void)checkNetworkStatus {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        PEPNetworkStatus pStatus = PEPNetworkStatusUnknown;
        switch (status) {
            case AFNetworkReachabilityStatusUnknown: {
                pStatus = PEPNetworkStatusUnknown;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                pStatus = PEPNetworkStatusReachableViaWiFi;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN: {
                pStatus = PEPNetworkStatusReachableViaWWAN;
                break;
            }
            case AFNetworkReachabilityStatusNotReachable: {
                pStatus = PEPNetworkStatusNotReachable;
                break;
            }
        }
        
        if (self.status == pStatus) { return; }
        
        self.status = pStatus;
        if (self.statusChangeBlock) {
            self.statusChangeBlock(pStatus);
        }
    }];
}

- (void)setStatus:(PEPNetworkStatus)status {
    if (_status != status) {
        _status = status;
        
        if (self.statusChangeBlock) self.statusChangeBlock(status);
    }
}

@end
