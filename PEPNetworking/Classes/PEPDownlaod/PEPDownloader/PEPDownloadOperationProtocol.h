//
//  PEPDownloadOperationProtocol.h
//  PEPDownloader
//
//  Created by ChenJianjun on 16/5/23.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEPDownloadOperation;

/** Download operation protocol. */
@protocol PEPDownloadOperationProtocol <NSObject>

/** Start download operation. */
- (void)startDownload:(PEPDownloadOperation *)operation;

/** Pause download operation. */
- (void)pauseDownload:(PEPDownloadOperation *)operation;

/** Finish download operation. */
- (void)finishDownload:(PEPDownloadOperation *)operation;

/** Finish download operation and remove download files. */
- (void)removeDownload:(PEPDownloadOperation *)operation;

@end
