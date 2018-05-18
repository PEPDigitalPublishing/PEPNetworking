//
//  PEPDownloadQueue.m
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/23.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import "PEPDownloadQueue.h"
#import "PEPDownloadOperation.h"
#import "PEPDownloadManager.h"

@interface PEPDownloadQueue ()

@property (nonatomic, assign) NSInteger currentDownloadCount;
@property (nonatomic, strong) NSMutableArray *operationList;

@end

@implementation PEPDownloadQueue

- (instancetype)init
{
    if (self = [super init]) {
        _maxConcurrentDownloadCount = 3;
        _operationList = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)sharedQueue
{
    static PEPDownloadQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [[PEPDownloadQueue alloc] init];
    });
    return sharedQueue;
}

- (void)startDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    
    if (![self downloadOperation:operation.item.downloadId
                         groupId:operation.item.groupId]) {
        @synchronized(self.operationList) {
            [self.operationList addObject:operation];
        }
    }
    
    if (self.currentDownloadCount >= self.maxConcurrentDownloadCount) {
        operation.item.status = PEPDownloadStatusWait;
        return;
    }
    if (operation.item.status == PEPDownloadStatusDownloading) {
        [self startNextDownload];
        return;
    }
    operation.item.status = PEPDownloadStatusDownloading;
    [[PEPDownloadManager sharedManager] startDownload:operation];
}

- (void)pauseDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    if (operation.item.status == PEPDownloadStatusWait
        || operation.item.status == PEPDownloadStatusDownloading) {
        operation.item.status = PEPDownloadStatusPause;
        [[PEPDownloadManager sharedManager] pauseDownload:operation];
    }
}

- (void)finishDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    if (operation.item.status == PEPDownloadStatusWait
        || operation.item.status == PEPDownloadStatusDownloading) {
        operation.item.status = PEPDownloadStatusFinished;
    }
    [[PEPDownloadManager sharedManager] finishDownload:operation];
    if (operation.item.status == PEPDownloadStatusUnknownError) {
        @synchronized(self.operationList) {
            [self.operationList removeObject:operation];
        }
    }
    if (self.currentDownloadCount < self.maxConcurrentDownloadCount) {
        [self startNextDownload];
    }
}

- (void)removeDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    [[PEPDownloadManager sharedManager] removeDownload:operation];
    @synchronized(self.operationList) {
        [self.operationList removeObject:operation];
    }
}

- (void)removeOperationFromList:(PEPDownloadOperation *)operation{
    if (operation) {
        @synchronized (self.operationList) {
            [self.operationList removeObject:operation];
        }
    }
}

#pragma mark - Downloads operation with groupId

- (void)startDownloadList:(NSArray<PEPDownloadOperation *> *)downloadList
{
    [downloadList enumerateObjectsUsingBlock:^(PEPDownloadOperation *operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [operation startDownload];
    }];
}

- (void)startDownloadsWithGroupId:(NSString *)groupId
{
    for (PEPDownloadOperation *operation in self.operationList) {
        if (groupId.length > 0 && ![operation.item.groupId isEqualToString:groupId]) {
            continue;
        }
        if (operation.item.status == PEPDownloadStatusPause
            || operation.item.status == PEPDownloadStatusUnknownError) {
            operation.item.status = PEPDownloadStatusWait;
        }
        [self startDownload:operation];
    }
}

- (void)pauseDownloadsWithGroupId:(NSString *)groupId
{
    for (PEPDownloadOperation *operation in self.operationList) {
        if (groupId.length > 0 && ![operation.item.groupId isEqualToString:groupId]) {
            continue;
        }
        [operation pauseDownload];
    }
}

- (void)removeDownloadsWithGroupId:(NSString *)groupId
{
    NSMutableArray *removeArray = [NSMutableArray array];
    for (PEPDownloadOperation *operation in self.operationList) {
        if (groupId.length > 0 && ![operation.item.groupId isEqualToString:groupId]) {
            continue;
        }
        [removeArray addObject:operation];
    }
    [removeArray enumerateObjectsUsingBlock:^(PEPDownloadOperation *operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [operation removeDownload];
    }];
    [removeArray removeAllObjects];
    
    if (self.currentDownloadCount < self.maxConcurrentDownloadCount) {
        [self startNextDownload];
    }
}

- (void)removeDownloadWithDownloadID:(NSString *)downloadID{
    
    NSMutableArray *removeArray = [NSMutableArray array];
    for (PEPDownloadOperation *operation in self.operationList) {
        if ([operation.item.downloadId isEqualToString:downloadID]) {
            [removeArray addObject:operation];
        }
    }
    [removeArray enumerateObjectsUsingBlock:^(PEPDownloadOperation *operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [operation removeDownload];
    }];
    
    if (self.currentDownloadCount < self.maxConcurrentDownloadCount) {
        [self startNextDownload];
    }
}

- (void)removeAllDownloads{
    //取消全部任务
    [self.operationList enumerateObjectsUsingBlock:^(PEPDownloadOperation *operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [[PEPDownloadManager sharedManager] finishDownload:operation];
    }];
    
    [self.operationList removeAllObjects];
    
}

- (NSArray<PEPDownloadOperation *> *)downloadListWithGroupId:(NSString *)groupId
{
    if (groupId.length < 1) {
        return self.operationList;
    }
    
    NSMutableArray *operationList = [NSMutableArray array];
    for (PEPDownloadOperation *operation in self.operationList) {
        if ([operation.item.groupId isEqualToString:groupId]) {
            [operationList addObject:operation];
        }
    }
    return operationList;
}

- (PEPDownloadOperation *)downloadOperation:(NSString *)downloadId
                                   groupId:(NSString *)groupId
{
    if (downloadId.length < 1) {
        return nil;
    }
    __block PEPDownloadOperation *operation = nil;
    [self.operationList enumerateObjectsUsingBlock:^(PEPDownloadOperation *op, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL sameGroupId = (groupId.length < 1) || (groupId.length > 0 && [groupId isEqualToString:op.item.groupId]);
        if (sameGroupId && [downloadId isEqualToString:op.item.downloadId]) {
            operation = op;
            *stop = YES;
        }
    }];
    return operation;
}

#pragma mark - Private

- (NSInteger)currentDownloadCount
{
    NSInteger count = 0;
   
    @synchronized (self.operationList) {
        for (PEPDownloadOperation *operation in self.operationList) {
            if (operation.item.status == PEPDownloadStatusDownloading) {
                count += 1;
            }
        }
    }
   
    _currentDownloadCount = count;
    return count;
}

- (void)startNextDownload
{
    for (PEPDownloadOperation *operation in self.operationList) {
        if (operation.item.status == PEPDownloadStatusWait) {
            [self startDownload:operation];
            break;
        }
    }
}

@end
