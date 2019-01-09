//
//  PEPDownloadManager.m
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/21.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import "PEPDownloadManager.h"
#import "PEPDownloadOperation.h"
#import "PEPDownloadUtilities.h"

static NSString *const PEPDownloadManagerFolder = @"com.PEP.PEPDownloader.folder";

static dispatch_queue_t PEP_download_agent_file_operation_queue() {
    static dispatch_queue_t download_agent_file_operation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        download_agent_file_operation_queue = dispatch_queue_create("com.PEP.PEPDownloader.download.agent.file.operation", DISPATCH_QUEUE_SERIAL);
    });
    return download_agent_file_operation_queue;
}

@interface PEPDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *tasksDict;
@property (nonatomic, strong) NSMutableDictionary *pauseAndResumeDict;

@end

@implementation PEPDownloadManager

- (instancetype)init
{
    if (self = [super init]) {
        _tasksDict = [NSMutableDictionary dictionary];
        _manager = [AFHTTPSessionManager manager];
//        [_manager.requestSerializer setValue:[PEPUserManager sharedPEPUserManager].JSESSIONID forHTTPHeaderField:@"Cookie"];
//        [_manager.requestSerializer setValue:[PEPUserManager sharedPEPUserManager].GSID forHTTPHeaderField:@"GSID"];
        _minFileSizeForAutoProducingResumeData = 2 * 1024 * 1024;
        _pauseAndResumeDict = [NSMutableDictionary dictionary];
        [self removeInvalidTempFiles];
    }
    return self;
}

+ (instancetype)sharedManager
{
    static PEPDownloadManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[PEPDownloadManager alloc] init];
    });
    return sharedManager;
}

- (BOOL)isFileDownloaded:(PEPDownloadItem *)downloadItem
{
    int64_t fileSize = [PEPDownloadUtilities fileSizeWithFilePath:downloadItem.downloadFilePath];
    if (fileSize > 0
        && fileSize >= downloadItem.totalUnitCount) {
        return YES;
    }
    return NO;
}

- (void)removeDownloadFile:(PEPDownloadItem *)downloadItem
{
    [self removeDownloadFile:downloadItem isDownloading:NO];
}

#pragma mark - PEPDownloadOperationProtocol

- (void)startDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    
    if (![self isValidDownload:operation.item]) {
        NSError *error = [NSError errorWithDomain:@"illegal download request." code:-1 userInfo:@{NSLocalizedDescriptionKey: @"非法下载请求"}];
        [self completionWithOperation:operation
                             filePath:nil
                                error:error];
        return;
    }
    
    if ([self isFileDownloaded:operation.item]) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:operation.item.downloadFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:operation.item.downloadFilePath error:nil];
        }
        
//        int64_t fileSize = [PEPDownloadUtilities fileSizeWithFilePath:operation.item.downloadFilePath];
//        operation.item.totalUnitCount = fileSize;
//        operation.item.completedUnitCount = fileSize;
//        [self completionWithOperation:operation
//                             filePath:[NSURL fileURLWithPath:operation.item.downloadFilePath]
//                                error:nil];
//        return;
    }
    
    NSString *key = [self downloadKey:operation.item];
    NSURLSessionDownloadTask *task = [self downloadTaskWithOperation:operation];
    if (task) {
        @synchronized(self.tasksDict) {
            self.tasksDict[key] = task;
        }
    }
}

- (void)pauseDownload:(PEPDownloadOperation *)operation
{
    [self pauseDownload:operation
             completion:nil];
}

- (void)finishDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    
    NSString *key = [self downloadKey:operation.item] ? : @"";
    NSURLSessionDownloadTask *requestTask = self.tasksDict[key];
    if ([requestTask respondsToSelector:@selector(cancel)]) {
        [requestTask cancel];
    }
    @synchronized(self.tasksDict) {
        [self.tasksDict removeObjectForKey:key];
    }
}

- (void)removeDownload:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    
    NSString *key = [self downloadKey:operation.item];
    NSURLSessionDownloadTask *requestTask = self.tasksDict[key];
    if ([requestTask respondsToSelector:@selector(cancel)]) {
        [requestTask cancel];
    }
    @synchronized(self.tasksDict) {
        [self.tasksDict removeObjectForKey:key];
    }
    [self removeDownloadFile:operation.item isDownloading:YES];
}

#pragma mark - download operation

- (NSString *)downloadKey:(PEPDownloadItem *)downloadItem
{
    return downloadItem.downloadId;
}

- (BOOL)isValidDownload:(PEPDownloadItem *)downloadItem
{
    if (downloadItem.downloadUrl.length > 0
        && downloadItem.downloadFilePath.length > 0) {
        return YES;
    }
    return NO;
}

- (void)pauseDownload:(PEPDownloadOperation *)operation
           completion:(void(^)(BOOL isSuccess))completion
{
    if (!operation) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    NSString *key = [self downloadKey:operation.item];
    NSURLSessionDownloadTask *requestTask = self.tasksDict[key];
    if ([requestTask respondsToSelector:@selector(cancelByProducingResumeData:)]) {
        __weak __typeof(self)weakSelf = self;
        [requestTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf saveResumeData:resumeData downloadItem:operation.item completion:^(BOOL isSaved) {
                if (completion) {
                    completion(isSaved);
                }
            }];
        }];
    }
    @synchronized(self.tasksDict) {
        [self.tasksDict removeObjectForKey:key];
    }
}

/** Remove invalid download temp files. */
- (void)removeInvalidTempFiles
{
    NSString *tempPath = NSTemporaryDirectory();
    NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempPath error:nil];
    for (NSString *fileName in tempFiles) {
        NSString *filePath = [tempPath stringByAppendingPathComponent:fileName];
        if ([PEPDownloadUtilities fileSizeWithFilePath:filePath] == 0) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

/** Remove download file.
 * @param isDownloading Is download task in progress or not.
 */
- (void)removeDownloadFile:(PEPDownloadItem *)downloadItem
             isDownloading:(BOOL)isDownloading
{
    dispatch_async(PEP_download_agent_file_operation_queue(), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadItem.downloadFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:downloadItem.downloadFilePath error:nil];
        }
    });
    if (isDownloading) {
        [self removeResumeData:downloadItem];
    } else {
        [self removeTempFileAndResumeData:downloadItem];
    }
}

#pragma mark - resume data operation
- (NSString *)resumeDataFolderPath{
    
    
    return nil;
}

- (NSString *)resumeDataPath:(PEPDownloadItem *)downloadItem
{
    if (downloadItem == nil || downloadItem.downloadId.length == 0) { return @""; }

    NSString *key = [self downloadKey:downloadItem];
    NSString *resumeDataName = [NSString stringWithFormat:@"%@_resumeData", key];
    NSString *resumeDataPath = [PEPDownloadUtilities filePathWithFileName:resumeDataName
                                                              folderName:PEPDownloadManagerFolder];
    return resumeDataPath;
}

- (void)removeResumeData:(PEPDownloadItem *)downloadItem
{
    dispatch_async(PEP_download_agent_file_operation_queue(), ^{
        NSString *resumeDataPath = [self resumeDataPath:downloadItem];
        if (resumeDataPath.length > 0
            && [[NSFileManager defaultManager] fileExistsAtPath:resumeDataPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:resumeDataPath error:nil];
        }
    });
}

- (void)removeTempFileAndResumeData:(PEPDownloadItem *)downloadItem
{
    dispatch_async(PEP_download_agent_file_operation_queue(), ^{
        NSString *resumeDataPath = [self resumeDataPath:downloadItem];
        if (resumeDataPath.length > 0
            && [[NSFileManager defaultManager] fileExistsAtPath:resumeDataPath]) {
            NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
            NSDictionary *resumeDictionary = [self resumeDictionaryWithResumeData:resumeData];
            NSString *tempFilePath = [self tempFilePathWithResumeDictionary:resumeDictionary];
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
            }
            [[NSFileManager defaultManager] removeItemAtPath:resumeDataPath error:nil];
        }
    });
}

- (void)saveResumeData:(NSData *)resumeData
          downloadItem:(PEPDownloadItem *)downloadItem
{
    [self saveResumeData:resumeData
            downloadItem:downloadItem
              completion:nil];
}

- (void)saveResumeData:(NSData *)resumeData
          downloadItem:(PEPDownloadItem *)downloadItem
            completion:(void(^)(BOOL isSaved))completion
{
    if (!resumeData
        || ![self resumeDataPath:downloadItem]) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    dispatch_async(PEP_download_agent_file_operation_queue(), ^{
        BOOL saved = [resumeData writeToFile:[self resumeDataPath:downloadItem] atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(saved);
            }
        });
    });
}

- (NSData *)validResumeData:(PEPDownloadItem *)downloadItem
{
    NSString *resumeDataPath = [self resumeDataPath:downloadItem];
    if (resumeDataPath.length < 1
        || ![[NSFileManager defaultManager] fileExistsAtPath:resumeDataPath]) {
        return nil;
    }
    
    NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
    NSDictionary *resumeDictionary = [self resumeDictionaryWithResumeData:resumeData];
    //Check is download temp file exists or not
    NSString *tempFilePath = [self tempFilePathWithResumeDictionary:resumeDictionary];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
        return nil;
    }
    
    //Update resumeData info.
    BOOL isResumeDataChanged = NO;
    NSMutableDictionary *newResumeDictionary = [NSMutableDictionary dictionaryWithDictionary:resumeDictionary];
    
    //Check download url
    NSString *downloadUrl = [resumeDictionary objectForKey:@"NSURLSessionDownloadURL"];
    if (![downloadUrl isEqualToString:downloadItem.downloadUrl]) {
        isResumeDataChanged = YES;
        newResumeDictionary[@"NSURLSessionDownloadURL"] = downloadItem.downloadUrl;
    }
    
    //Check resume bytes received
    int64_t bytesReceived = [[resumeDictionary objectForKey:@"NSURLSessionResumeBytesReceived"] longLongValue];
    int64_t fileSize = [PEPDownloadUtilities fileSizeWithFilePath:tempFilePath];
    if (bytesReceived < fileSize) {
        isResumeDataChanged = YES;
        newResumeDictionary[@"NSURLSessionResumeBytesReceived"] = @(fileSize);
    }
    if (isResumeDataChanged) {
        NSError *error;
        NSData *newResumeData = [NSPropertyListSerialization dataWithPropertyList:newResumeDictionary format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&error];
        if (!error && newResumeData) {
            resumeData = newResumeData;
            [self saveResumeData:resumeData
                    downloadItem:downloadItem];
        }
    }
    return resumeData;
}

/** ResumeData serialization. */
- (NSDictionary *)resumeDictionaryWithResumeData:(NSData *)resumeData
{
    if (resumeData.length < 1) {
        return nil;
    }
    return [NSPropertyListSerialization propertyListWithData:resumeData
                                                     options:NSPropertyListImmutable
                                                      format:NULL
                                                       error:nil];
}

/** Download temp file path. */
- (NSString *)tempFilePathWithResumeDictionary:(NSDictionary *)resumeDictionary
{
    if (resumeDictionary.count < 1) {
        return nil;
    }
    NSString *tempFileName = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoTempFileName"];
    if (tempFileName.length < 1) {
        return nil;
    }
    return [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
}

#pragma mark - pause download and produce resume data

/** Pause download to produce resumeData, after that restart the download. */
- (void)pauseAndResumeOperation:(PEPDownloadOperation *)operation
{
    if (operation.item.totalUnitCount < self.minFileSizeForAutoProducingResumeData) {
        return;
    }
    NSString *resumeDataPath = [self resumeDataPath:operation.item];
    int64_t fileSize = [PEPDownloadUtilities fileSizeWithFilePath:resumeDataPath];
    if (fileSize > 0) {
        return;
    }
    
    [self addPauseAndResumeOperation:operation];
    __weak __typeof(self)weakSelf = self;
    operation.item.status = PEPDownloadStatusPause;
    [self pauseDownload:operation completion:^(BOOL isSuccess) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        operation.item.status = PEPDownloadStatusDownloading;
        [strongSelf startDownload:operation];
    }];
}

- (void)addPauseAndResumeOperation:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return;
    }
    NSString *key = [self downloadKey:operation.item];
    @synchronized(self.pauseAndResumeDict) {
        self.pauseAndResumeDict[key] = operation;
    }
}

- (void)removePauseAndResumeOperation:(PEPDownloadOperation *)operation
{
    if (![self isPauseAndResumeOperation:operation]) {
        return;
    }
    NSString *key = [self downloadKey:operation.item];
    @synchronized(self.pauseAndResumeDict) {
        [self.pauseAndResumeDict removeObjectForKey:key];
    }
}

- (BOOL)isPauseAndResumeOperation:(PEPDownloadOperation *)operation
{
    if (!operation) {
        return NO;
    }
    NSString *key = [self downloadKey:operation.item];
    return [self.pauseAndResumeDict.allKeys containsObject:key];
}

#pragma mark - Network

- (NSURLSessionDownloadTask *)downloadTaskWithOperation:(PEPDownloadOperation *)operation
{
//    [self.manager.requestSerializer setValue:[PEPUserManager sharedPEPUserManager].JSESSIONID forHTTPHeaderField:@"Cookie"];
//    [self.manager.requestSerializer setValue:[PEPUserManager sharedPEPUserManager].GSID forHTTPHeaderField:@"GSID"];
    
    NSURLSessionDownloadTask *task = nil;
    NSData *resumeData = [self validResumeData:operation.item];
    __weak __typeof(self)weakSelf = self;
    if (resumeData) {
        task = [self.manager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf downloadWithOperation:operation
                                         progress:downloadProgress];
                [strongSelf removePauseAndResumeOperation:operation];
            });
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:operation.item.downloadFilePath];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf completionWithOperation:operation
                                       filePath:filePath
                                          error:error];
        }];
        [task resume];
    } else {
        NSError *serializationError = nil;
        NSMutableURLRequest *urlRequest = [self.manager.requestSerializer requestWithMethod:@"GET" URLString:[operation.item.downloadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:nil error:&serializationError];
        if (serializationError) {
            [self completionWithOperation:operation
                                 filePath:nil
                                    error:serializationError];
            return nil;
        }   
        task = [self.manager downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf downloadWithOperation:operation
                                         progress:downloadProgress];
                [strongSelf pauseAndResumeOperation:operation];
            });
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:operation.item.downloadFilePath];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
           //防止暂停时执行error回调
            if (error && [strongSelf isPauseAndResumeOperation:operation]) {
                return;
            }else if (error){
                // FIXME: ↓自行修改，删除下载失败时默认创建的文件
                if ([[NSFileManager defaultManager] fileExistsAtPath:operation.item.downloadFilePath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:operation.item.downloadFilePath error:nil];
                }
            }
            [strongSelf completionWithOperation:operation
                                       filePath:filePath
                                          error:error];
        }];
        [task resume];
    }
    return task;
}

- (void)downloadWithOperation:(PEPDownloadOperation *)operation
                     progress:(NSProgress *)progress
{
    if (!progress) {
        return;
    }
    operation.item.totalUnitCount = progress.totalUnitCount;
    operation.item.completedUnitCount = progress.completedUnitCount;
    [[NSNotificationCenter defaultCenter] postNotificationName:PEPDownloadProgressNotification
                                                        object:nil
                                                      userInfo:@{PEPDownloadIdKey:operation.item.downloadId, PEPDownloadProgressKey:progress}];
    if (operation.progressBlock) {
        operation.progressBlock(progress);
    }
}

- (void)completionWithOperation:(PEPDownloadOperation *)operation
                       filePath:(NSURL *)filePath
                          error:(NSError *)error
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error) {
        userInfo[PEPDownloadCompletionErrorKey] = error;
        if (operation.item.status == PEPDownloadStatusDownloading) {
            operation.item.status = PEPDownloadStatusUnknownError;
        }
        if (error.code != NSURLErrorCancelled
            && [error.userInfo.allKeys containsObject:NSURLSessionDownloadTaskResumeData]) {
            [self saveResumeData:error.userInfo[NSURLSessionDownloadTaskResumeData]
                    downloadItem:operation.item];
        }
    } else if (filePath) {
        userInfo[PEPDownloadCompletionFilePathKey] = filePath;
        operation.item.status = PEPDownloadStatusFinished;
        [self removeResumeData:operation.item];
    }
    
    if (userInfo.count > 0) {
        userInfo[PEPDownloadIdKey] = operation.item.downloadId;
        [[NSNotificationCenter defaultCenter] postNotificationName:PEPDownloadCompletionNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    if (operation.completionBlock) {
        operation.completionBlock(filePath, error);
    }
    [operation finishDownload];
}

@end
