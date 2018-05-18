//
//  PEPNetworkingDiskCache.h
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEPNetworkingDiskCache : NSObject

/**
 写入磁盘数据

 @param data 数据
 @param directory 写入目录
 @param fileName 文件名
 */
+ (void)writeData:(id)data toDirectory:(NSString *)directory fileName:(NSString *)fileName;

/**
 读取缓存数据

 @param directory 路径
 @param fileName 文件名
 @return 数据
 */
+ (id)readDataFromDirectory:(NSString *)directory fileName:(NSString *)fileName;

/**
 缓存目录文件大小

 @param directory 路径
 @return 大小
 */
+ (NSInteger)dataSizeAtDirectory:(NSString *)directory;

/**
 清空缓存目录文件

 @param directory 路径
 */
+ (void)clearDataAtDirectory:(NSString *)directory;

/**
 删除某文件

 @param filePath 文件路径
 */
+ (void)deleteCacheAtPath:(NSString *)filePath;

@end
