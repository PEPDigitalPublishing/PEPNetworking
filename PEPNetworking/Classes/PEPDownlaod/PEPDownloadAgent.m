//
//  PEPDownloadAgent.m
//  PEPNetwork
//
//  Created by Karl on 2018/1/25.
//  Copyright © 2018年 pep.com. All rights reserved.
//

#import "PEPDownloadAgent.h"
#import "PEPDownloader.h"
#import "PEPNetworkReachabilityManager.h"

@implementation PEPDownloadAgent

+ (PEPDownloadOperation *)downloadWithDownloadPath:(NSString *)downloadPath savePath:(NSString *)savePath progress:(PEPDownloadProgressBlock)progressBlock success:(PEPDownloadSuccessBlock)successBlock fail:(PEPDownloadFailBlock)failBlock{
    
    //检测网络环境
    PEPNetworkReachabilityManager *manager = [PEPNetworkReachabilityManager sharedManager];
    [manager checkNetworkStatus];
    if (manager.status == PEPNetworkStatusNotReachable) {
        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
        if (failBlock) {
            failBlock(error);
        }
        return nil;
    }
    PEPDownloadItem *item = [[PEPDownloadItem alloc] init];
    item.downloadUrl = downloadPath;
    item.downloadFilePath = savePath;
    PEPDownloadOperation *operation = [PEPDownloadOperation operationWithItem:item];
    [operation startWithProgressBlock:^(NSProgress *progress) {
        if (progressBlock) {
            progressBlock(progress);
        }
    } completionBlock:^(NSURL *filePath, NSError *error) {
        if (error && failBlock) {
            failBlock (error);
        }else if (!error && successBlock){
            successBlock(filePath);
        }
    }];
    
    return operation;
}

+ (void)coinfigHttpHeader:(NSDictionary *)httpHeader{
    for (NSString *key in httpHeader.allKeys) {
        if (httpHeader[key] != nil) {
            [[PEPDownloadManager sharedManager].manager.requestSerializer setValue:httpHeader[key] forHTTPHeaderField:key];
        }
    }
}


@end
