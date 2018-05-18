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


- (void)checkNetworkStatus{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                self.status = PEPNetworkStatusUnknown;
                if (self.statusChangeBlock) self.statusChangeBlock(PEPNetworkStatusUnknown);
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                self.status = PEPNetworkStatusReachableViaWiFi;
                if (self.statusChangeBlock) self.statusChangeBlock(PEPNetworkStatusReachableViaWiFi);
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                self.status = PEPNetworkStatusReachableViaWWAN;
                if (self.statusChangeBlock) self.statusChangeBlock(PEPNetworkStatusReachableViaWWAN);
                break;
            case AFNetworkReachabilityStatusNotReachable:
                self.status = PEPNetworkStatusNotReachable;
                if (self.statusChangeBlock) self.statusChangeBlock(PEPNetworkStatusNotReachable);
                break;
            default:
                break;
        }
    }];
}

@end
