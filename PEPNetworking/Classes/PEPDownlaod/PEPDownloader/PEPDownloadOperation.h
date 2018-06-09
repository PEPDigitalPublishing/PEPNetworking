//
//  PEPDownloadOperation.h
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/21.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Download status. */
typedef NS_ENUM(NSInteger, PEPDownloadStatus) {
    PEPDownloadStatusWait,        ///< waiting for download.
    PEPDownloadStatusDownloading, ///< in the download.
    PEPDownloadStatusPause,       ///< download is paused.
    PEPDownloadStatusFinished,    ///< download is finished.
    PEPDownloadStatusUnknownError ///< download error occured.
};

/** Download operation info Class. */
@interface PEPDownloadItem : NSObject

@property (nonatomic, strong) NSString *downloadUrl;      ///< download link, can't be nil.
@property (nonatomic, strong) NSString *downloadFilePath; ///< local path for file cache, can't be nil.
@property (nonatomic, strong) NSString *downloadId;       ///< if nil, generated automatically by the downloadUrl.
@property (nonatomic, strong) NSString *groupId;          ///< default is nil.
@property (nonatomic, assign) PEPDownloadStatus status;    ///< default is PEPDownloadStatusWait.
@property (nonatomic, assign) int64_t totalUnitCount;     ///< file size.
@property (nonatomic, assign) int64_t completedUnitCount; ///< completed download size of file.

@end

FOUNDATION_EXPORT NSNotificationName const PEPDownloadProgressNotification;   ///< notification of download progress.
FOUNDATION_EXPORT NSNotificationName const PEPDownloadCompletionNotification; ///< notification of download completion.
FOUNDATION_EXPORT NSString *const PEPDownloadIdKey;                  ///< download identifier key in notifications userInfo, instance type of the value is NSString.
FOUNDATION_EXPORT NSString *const PEPDownloadProgressKey;            ///< download progress key in PEPDownloadProgressNotification userInfo, instance type of the value is NSProgress.
FOUNDATION_EXPORT NSString *const PEPDownloadCompletionFilePathKey;  ///< download completion file path key in PEPDownloadCompletionNotification userInfo, instance type of the value is NSURL.
FOUNDATION_EXPORT NSString *const PEPDownloadCompletionErrorKey;     ///< download completion error key in PEPDownloadCompletionNotification userInfo, instance type of the value is NSError.

/** Block of file download progress. */
typedef void(^PEPDownloadProgressBlock)(NSProgress *progress);
/** Block of file download completion. */
typedef void(^PEPDownloadCompletionBlock)(NSURL *filePath, NSError *error);

/** Block of download status*/
typedef void(^PEPDownloadStatusChangedBlock)(PEPDownloadStatus status);
/** Download operation Class. */
@interface PEPDownloadOperation : NSObject

@property (nonatomic, strong, readonly) PEPDownloadItem *item;
@property (nonatomic, copy, readonly) PEPDownloadProgressBlock progressBlock;
@property (nonatomic, copy, readonly) PEPDownloadCompletionBlock completionBlock;
@property (nonatomic, copy) PEPDownloadStatusChangedBlock statusChangedBlock;

/** Instance of PEPDownloadOperation with item. */
+ (instancetype)operationWithItem:(PEPDownloadItem *)item;

/** Start download. */
- (void)startDownload;

/** Start download with progressBlock and completionBlock. */
- (void)startWithProgressBlock:(PEPDownloadProgressBlock)progressBlock
               completionBlock:(PEPDownloadCompletionBlock)completionBlock;

/** Reset progressBlock and completionBlock. */
- (void)resetProgressBlock:(PEPDownloadProgressBlock)progressBlock
           completionBlock:(PEPDownloadCompletionBlock)completionBlock;

/** Pause download. */
- (void)pauseDownload;

/** Finish download (download is completed or error occured). */
- (void)finishDownload;

/** Remove download (stop download operation and remove download files). */
- (void)removeDownload;

@end
