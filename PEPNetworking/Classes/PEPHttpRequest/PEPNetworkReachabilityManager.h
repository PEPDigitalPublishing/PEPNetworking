//
//  PEPNetworkReachabilityManager.h
//  AFNetworking
//
//  Created by Karl on 2018/2/28.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PEPNetworkStatus){
    /**
     *  未知网络
     */
    PEPNetworkStatusUnknown             = 1 << 0,
    /**
     *  无法连接
     */
    PEPNetworkStatusNotReachable        = 1 << 1,
    /**
     *  WWAN网络
     */
    PEPNetworkStatusReachableViaWWAN    = 1 << 2,
    /**
     *  WiFi网络
     */
    PEPNetworkStatusReachableViaWiFi    = 1 << 3
    
};

typedef void(^PEPNetworkStatusChangeBlock)(PEPNetworkStatus status);

@interface PEPNetworkReachabilityManager : NSObject

@property (nonatomic, assign) PEPNetworkStatus status;
@property (nonatomic, copy) PEPNetworkStatusChangeBlock statusChangeBlock;

+ (instancetype)sharedManager;

- (void)checkNetworkStatus;




@end
