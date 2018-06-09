//
//  PEPDownloadOperation.m
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/21.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import "PEPDownloadOperation.h"
#import "PEPDownloadQueue.h"
#import "PEPDownloadUtilities.h"

@implementation PEPDownloadItem

- (NSString *)downloadId
{
    if (_downloadId.length < 1) {
        _downloadId = [PEPDownloadUtilities md5WithString:self.downloadUrl];
    }
    return _downloadId;
}

@end

NSNotificationName const PEPDownloadProgressNotification = @"kPEPDownloadProgressNotification";
NSNotificationName const PEPDownloadCompletionNotification = @"kPEPDownloadCompletionNotification";
NSString *const PEPDownloadIdKey = @"kPEPDownloadIdKey";
NSString *const PEPDownloadProgressKey = @"kPEPDownloadProgressKey";
NSString *const PEPDownloadCompletionFilePathKey = @"kPEPDownloadCompletionFilePathKey";
NSString *const PEPDownloadCompletionErrorKey = @"kPEPDownloadCompletionErrorKey";

@interface PEPDownloadOperation ()

@property (nonatomic, strong) PEPDownloadItem *item;
@property (nonatomic, copy) PEPDownloadProgressBlock progressBlock;
@property (nonatomic, copy) PEPDownloadCompletionBlock completionBlock;

@end

@implementation PEPDownloadOperation

- (void)dealloc
{
    [self clearBlocks];
    [_item removeObserver:self forKeyPath:@"status"];
}

- (instancetype)initWithItem:(PEPDownloadItem *)item
{
    if (self = [super init]) {
        _item = item;
        [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

+ (instancetype)operationWithItem:(PEPDownloadItem *)item
{
    PEPDownloadOperation *operation = [[PEPDownloadQueue sharedQueue] downloadOperation:item.downloadId
                                                                              groupId:item.groupId];
    if (operation) {
        return operation;
    }
    return [[self alloc] initWithItem:item];
}

- (void)startDownload
{
    [[PEPDownloadQueue sharedQueue] startDownload:self];
}

- (void)startWithProgressBlock:(PEPDownloadProgressBlock)progressBlock
               completionBlock:(PEPDownloadCompletionBlock)completionBlock
{
    [self resetProgressBlock:progressBlock
             completionBlock:completionBlock];
    [self startDownload];
}

- (void)resetProgressBlock:(PEPDownloadProgressBlock)progressBlock
           completionBlock:(PEPDownloadCompletionBlock)completionBlock
{
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
}

- (void)pauseDownload
{
    [[PEPDownloadQueue sharedQueue] pauseDownload:self];
}

- (void)finishDownload
{
    [[PEPDownloadQueue sharedQueue] finishDownload:self];
}

- (void)removeDownload
{
    [self clearBlocks];
    [[PEPDownloadQueue sharedQueue] removeDownload:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        if (self.statusChangedBlock) {
            self.statusChangedBlock(_item.status);
        }
    }
}

#pragma mark -

- (void)clearBlocks
{
    self.completionBlock = nil;
    self.progressBlock = nil;
    self.statusChangedBlock = nil;
}

@end
