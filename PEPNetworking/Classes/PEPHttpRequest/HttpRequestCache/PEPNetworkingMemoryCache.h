//
//  PEPNetworkingMemoryCache.h
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEPNetworkingMemoryCache : NSObject

/**
 数据写入内存

 @param data 数据
 @param key  建值
 */
+ (void)writeData:(id)data forKey:(NSString *)key;

/**
 从内存读取数据

 @param key 键值
 @return    数据
 */
+ (id)readDataWithKey:(NSString *)key;

@end
