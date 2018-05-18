//
//  PEPDownloadQueue.h
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/23.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEPDownloadOperationProtocol.h"

@class PEPDownloadOperation;

/** File download queue class. */
@interface PEPDownloadQueue : NSObject <PEPDownloadOperationProtocol>

@property (nonatomic, assign) NSInteger maxConcurrentDownloadCount; ///< max concurrent download count, default is 10.
@property (nonatomic, assign, readonly) NSInteger currentDownloadCount; ///< current download count.

/** Singleton instance of PEPDownloadQueue. */
+ (instancetype)sharedQueue;

#pragma mark - Downloads operation with groupId

/** Start download operation with a group of PEPDownloadOperation. */
- (void)startDownloadList:(NSArray<PEPDownloadOperation *> *)downloadList;

/** Start downloads for groupId (download all when groupId is nil). */
- (void)startDownloadsWithGroupId:(NSString *)groupId;

/** Pause downloads for groupId (pause all when groupId is nil). */
- (void)pauseDownloadsWithGroupId:(NSString *)groupId;

/** Remove downloads for groupId (remove all when groupId is nil). */
- (void)removeDownloadsWithGroupId:(NSString *)groupId;

- (void)removeDownloadWithDownloadID:(NSString *)downloadID;

- (void)removeAllDownloads;

/** Returns a group of downloads for groupId (return all when groupId is nil). */
- (NSArray<PEPDownloadOperation *> *)downloadListWithGroupId:(NSString *)groupId;

/** Returns download operation with downloadId and groupId, returns nil if not start at all. */
- (PEPDownloadOperation *)downloadOperation:(NSString *)downloadId
                                   groupId:(NSString *)groupId;

- (void)removeOperationFromList:(PEPDownloadOperation *)operation;

@end
