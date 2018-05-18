//
//  PEPDownloadAgent.h
//  PEPNetwork
//
//  Created by Karl on 2018/1/25.
//  Copyright © 2018年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEPDownloadOperation.h"
typedef void (^PEPDownloadProgressBlock) (NSProgress *downloadProgress);
typedef void(^PEPDownloadSuccessBlock)(NSURL *filePath);
typedef void(^PEPDownloadFailBlock)(NSError *error);

@interface PEPDownloadAgent : NSObject


/**
 开启下载任务，支持断点续传

 @param downloadPath    下载路径
 @param savePath        本地储存路径
 @param progressBlock   进度回调
 @param successBlock    成功回调
 @param failBlock       失败回调
 */
+ (PEPDownloadOperation *)downloadWithDownloadPath:(NSString *)downloadPath
                        savePath:(NSString *)savePath
                        progress:(PEPDownloadProgressBlock)progressBlock
                         success:(PEPDownloadSuccessBlock)successBlock
                            fail:(PEPDownloadFailBlock)failBlock;

/**
 配置下载任务header

 @param httpHeader 请求头字典
 */
+ (void)coinfigHttpHeader:(NSDictionary *)httpHeader;


@end
