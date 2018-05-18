//
//  PEPNetworkingCacheManager.h
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEPNetworkingCacheManager : NSObject


/**
 初始化缓存器

 @return manager
 */
+ (PEPNetworkingCacheManager *)sharedManager;

/**
 配置缓存时间和缓存磁盘空间

 @param time     缓存时间
 @param capacity 磁盘空间
 */
- (void)setCacheTime:(NSTimeInterval)time diskCapacity:(NSUInteger)capacity;

/**
 缓存数据

 @param responseObject 接口返回数据
 @param requestUrl     请求地址
 @param params         请求参数
 */
- (void)cacheResponseObject:(id)responseObject requestUrl:(NSString *)requestUrl params:(NSDictionary *)params;

/**
 获取缓存数据

 @param requestUrl 请求地址
 @param params 请求参数
 @return 缓存数据
 */
- (id)getCachedResponseObjectWithRequestUrl:(NSString *)requestUrl params:(NSDictionary *)params;

/**
 获取缓存路径

 @return 缓存路径
 */
- (NSString *)getCacheDiretoryPath;

/**
 获取缓存大小

 @return 缓存大小
 */
- (NSUInteger)totalCachedSize;

/**
 清楚所有缓存
 */
- (void)clearTotalCache;

/**
 清除最近最少使用的缓存，LRU算法实现
 */
- (void)clearLRUCache;

@end
