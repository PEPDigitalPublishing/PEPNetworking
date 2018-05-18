//
//  PEPNetworkingMemoryCache.m
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import "PEPNetworkingMemoryCache.h"
#import <UIKit/UIKit.h>
static NSCache *sharedCache;

@implementation PEPNetworkingMemoryCache

+ (NSCache *)sharedCache{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedCache) {
            sharedCache = [[NSCache alloc] init];
        }
    });
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [sharedCache removeAllObjects];
    }];
    return sharedCache;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

+ (void)writeData:(id)data forKey:(NSString *)key{
    assert(data);
    assert(key);
    NSCache *cache = [PEPNetworkingMemoryCache sharedCache];
    [cache setObject:data forKey:key];
}

+ (id)readDataWithKey:(NSString *)key{
    assert(key);
    id data = nil;
    NSCache *cache = [PEPNetworkingMemoryCache sharedCache];
    data = [cache objectForKey:key];
    return data;
}



@end
