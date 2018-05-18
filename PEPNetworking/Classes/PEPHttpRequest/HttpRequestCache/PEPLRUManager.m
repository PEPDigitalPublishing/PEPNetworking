//
//  PEPLRUManager.m
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import "PEPLRUManager.h"

static NSMutableArray *operationQueue = nil;
static PEPLRUManager *manager = nil;
static NSString *const PEPLRUManagerName = @"PEPLRUManagerName";

@implementation PEPLRUManager

+ (PEPLRUManager *)sharedManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PEPLRUManager alloc] init];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:PEPLRUManagerName]) {
            operationQueue = [NSMutableArray arrayWithArray:(NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:PEPLRUManagerName]];
        }else{
            operationQueue = [NSMutableArray array];
        }
    });
    return manager;
}

-(void)addFileNode:(NSString *)fileName{
    NSArray *array = [operationQueue copy];
    //反向遍历数组
    [array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"fileName"] isEqualToString:fileName]) {
            //如果缓存目标存在,删除并重新添加
            [operationQueue removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    //添加对象
    NSDate *date = [NSDate date];
    NSDictionary *newDic = @{@"fileName":fileName,
                             @"date":date
                             };
    [operationQueue addObject:newDic];
    [[NSUserDefaults standardUserDefaults] setObject:[operationQueue copy] forKey:PEPLRUManagerName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (void)refreshIndexOfFileName:(NSString *)fileName{
    //刷新缓存时间
    [self addFileNode:fileName];
}

- (NSArray *)removeLRUFileNodeWithCacheTime:(NSTimeInterval)time{
    NSMutableArray *result = [NSMutableArray array];
    if (operationQueue.count > 0) {
        
        NSArray *tmpArray = [operationQueue copy];
        [tmpArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDate *date = obj[@"date"];
            NSDate *newDate = [date dateByAddingTimeInterval:time];
            //筛选出过期缓存，删除
            if ([[NSDate date] compare:newDate] == NSOrderedDescending) {
                [result addObject:obj[@"fileName"]];
                [operationQueue removeObjectAtIndex:idx];
            }
        }];
        if (result.count == 0) {
            NSString *removeFileName = [operationQueue firstObject][@"fileName"];
            [result addObject:removeFileName];
            [operationQueue removeObjectAtIndex:0];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:[operationQueue copy] forKey:PEPLRUManagerName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return  [result copy];
}


@end
