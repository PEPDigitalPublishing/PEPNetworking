//
//  PEPDownloadManager.h
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/21.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEPDownloadOperationProtocol.h"
#import <AFNetworking/AFNetworking.h>
@class PEPDownloadItem;

/** File download agent class. */
@interface PEPDownloadManager : NSObject <PEPDownloadOperationProtocol>

@property (nonatomic, assign) int64_t minFileSizeForAutoProducingResumeData; ///< minimum file size for automatically producing resumeData, default is 2M.

@property (nonatomic, strong) AFHTTPSessionManager *manager;

/** Singleton instance of PEPDownloadManager. */
+ (instancetype)sharedManager;

/** Check file is downloaded or not. */
- (BOOL)isFileDownloaded:(PEPDownloadItem *)downloadItem;

/** Delete downloaded files. 
 *  @param downloadItem download operation info. It is prohibited to call the method when the download task is in the progress, which avoid conflicts with the system to write or delete the download temporary files.
 */
- (void)removeDownloadFile:(PEPDownloadItem *)downloadItem;

/**
 returen resume data folder path
 */
- (NSString *)resumeDataFolderPath;

@end
