//
//  PEPNetworkingDiskCache.m
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import "PEPNetworkingDiskCache.h"

@implementation PEPNetworkingDiskCache

+ (void)writeData:(id)data toDirectory:(NSString *)directory fileName:(NSString *)fileName{
    
    assert(data);
    
    assert(directory);
    
    assert(fileName);
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (error) {
        NSLog(@"createDirectory error is %@",error.localizedDescription);
        return;
    }
    
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];
    
}

+ (id)readDataFromDirectory:(NSString *)directory fileName:(NSString *)fileName{
    assert(directory);
    assert(fileName);
    NSData *data = nil;
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    return data;
}

+ (NSInteger)dataSizeAtDirectory:(NSString *)directory{
    if (!directory) {
        return 0;
    }
    BOOL isDir = NO;
    NSUInteger totalSize = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) {
        NSError *error = nil;
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
        if (!error) {
            for (NSString *subFile in array) {
                NSString *filePath = [directory stringByAppendingPathComponent:subFile];
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
                if (!error) {
                    totalSize += [attributes[NSFileSize] unsignedIntegerValue];
                }
            }
        }
    }
    return totalSize;
}

+ (void)clearDataAtDirectory:(NSString *)directory{
    if (directory) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:directory]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:directory error:&error];
            if (error) {
                NSLog(@"清理缓存出错:%@",error.localizedDescription);
            }
        }
    }
}

+ (void)deleteCacheAtPath:(NSString *)filePath{
    if (filePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"删除文件出现错误出现错误：%@",error.localizedDescription);
            }
        }else {
            NSLog(@"不存在文件");
        }
    }
}

@end
