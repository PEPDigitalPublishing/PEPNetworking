//
//  PEPNetworkingCacheManager.m
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import "PEPNetworkingCacheManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "PEPNetworkingMemoryCache.h"
#import "PEPNetworkingDiskCache.h"
#import "PEPLRUManager.h"
//磁盘缓存容量-30M
static NSUInteger disCacheCapacity = 30 * 1024 * 1024;
//默认缓存时间-7天
static NSTimeInterval cacheTime = 7 * 24 * 60 * 60;

static NSString *const cacheDirKey = @"pepnetworkingdiskcachedirectorykey";
@implementation PEPNetworkingCacheManager

+ (PEPNetworkingCacheManager *)sharedManager{
    static PEPNetworkingCacheManager *cacheManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheManager = [[PEPNetworkingCacheManager alloc] init];
    });
    return cacheManager;
}

- (void)setCacheTime:(NSTimeInterval)time diskCapacity:(NSUInteger)capacity{
    disCacheCapacity = capacity;
    cacheTime = time;
}

-(void)cacheResponseObject:(id)responseObject requestUrl:(NSString *)requestUrl params:(NSDictionary *)params{
    assert(responseObject);
    assert(requestUrl);
    if (!params) {
        params = @{};
    }
    NSData *data = nil;
    NSString *md5Sting = [self md5String:[NSString stringWithFormat:@"%@%@",requestUrl,params]];
    NSError *error = nil;
    if ([responseObject isKindOfClass:[NSData class]]) {
        data = responseObject;
    }else if ([responseObject isKindOfClass:[NSDictionary class]]){
        data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
    }
    if (!error) {
        //缓存到内存
        [PEPNetworkingMemoryCache writeData:responseObject forKey:md5Sting];
        //缓存到磁盘
        NSString *directoryPath = nil;
        directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
        if (!directoryPath) {
            directoryPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"PEPNetworking"] stringByAppendingPathComponent:@"networkCache"];
            [[NSUserDefaults standardUserDefaults] setObject:directoryPath forKey:cacheDirKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [PEPNetworkingDiskCache writeData:data toDirectory:directoryPath fileName:md5Sting];
        [[PEPLRUManager sharedManager] addFileNode:md5Sting];
    }
}

- (id)getCachedResponseObjectWithRequestUrl:(NSString *)requestUrl params:(NSDictionary *)params{
    assert(requestUrl);
    id cachedData = nil;
    if (!params) {
        params = @{};
    }
    NSString *originString = [NSString stringWithFormat:@"%@%@",requestUrl,params];
    NSString *md5String = [self md5String:originString];
    //先从内存中找
    cachedData = [PEPNetworkingMemoryCache readDataWithKey:md5String];
    if (!cachedData) {
        NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
        if (directoryPath) {
            cachedData = [PEPNetworkingDiskCache readDataFromDirectory:directoryPath fileName:md5String];
            if (cachedData) {
                //刷新磁盘缓存队列
                [[PEPLRUManager sharedManager] refreshIndexOfFileName:md5String];
            }
        }
    }
    if ([cachedData isKindOfClass:[NSData class]]) {
        cachedData = [NSJSONSerialization JSONObjectWithData:cachedData options:NSJSONReadingMutableContainers error:nil];
    }
    return cachedData;
}

- (NSUInteger)totalCachedSize{
    NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
    return [PEPNetworkingDiskCache dataSizeAtDirectory:directoryPath];
}

- (NSString *)getCacheDiretoryPath {
    NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
    return directoryPath;
}

- (void)clearTotalCache{
    NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
    [PEPNetworkingDiskCache clearDataAtDirectory:directoryPath];
}

- (void)clearLRUCache{
    if ([self totalCachedSize] > disCacheCapacity) {
        NSArray *filesToDelete = [[PEPLRUManager sharedManager] removeLRUFileNodeWithCacheTime:cacheTime];
        NSString *directoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:cacheDirKey];
        if (directoryPath && filesToDelete.count) {
            [filesToDelete enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *filepath = [directoryPath stringByAppendingPathComponent:obj];
                [PEPNetworkingDiskCache deleteCacheAtPath:filepath];
            }];
        }
    }
}
- (NSString *)md5String:(NSString *)string{
    if (string == nil || string.length == 0) {
        return nil;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH],i;
    
    CC_MD5([string UTF8String],(int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],digest);
    
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x",(int)(digest[i])];
    }
    
    return [ms copy];
}
@end
