//
//  PEPLRUManager.h
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEPLRUManager : NSObject

+ (PEPLRUManager *)sharedManager;

/**
 添加一个新节点

 @param fileName 文件名
 */
- (void)addFileNode:(NSString *)fileName;

/**
 使用缓存文件时，调整节点位置

 @param fileName 文件名
 */
- (void)refreshIndexOfFileName:(NSString *)fileName;

/**
 删除最久未使用的缓存

 @param time 缓存时间
 @return 删除节点的文件列表
 */
- (NSArray *)removeLRUFileNodeWithCacheTime:(NSTimeInterval)time;

@end
