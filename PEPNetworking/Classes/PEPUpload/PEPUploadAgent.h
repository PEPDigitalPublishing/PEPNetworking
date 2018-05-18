//
//  PEPUploadAgent.h
//  PEPNetworking
//
//  Created by Karl on 2018/1/30.
//

#import <Foundation/Foundation.h>
#import "PEPUploadFormModel.h"

typedef void(^PEPProgressBlock) (int64_t completedBytes, int64_t totalBytes);
typedef void(^PEPResponseSuccessBlock) (id response);
typedef void(^PEPResponseFailBlock) (NSError *error);

@interface PEPUploadAgent : NSObject

/**
 异步上传任务
 @param url             上传url
 @param params          请求参数
 @pram  model           上传任务表单信息
 @param progressBlock   上传进度回调
 @param successBlock    上传成功回调
 @param failBlock       上传失败回调
 @return                返回上传任务对象
 */
+ (NSURLSessionTask *)uploadWithUrl:(NSString *)url
                             params:(NSDictionary *)params
                          formModel:(PEPUploadFormModel *)model
                      progressBlcok:(PEPProgressBlock)progressBlock
                       successBlock:(PEPResponseSuccessBlock)successBlock
                          failBlock:(PEPResponseFailBlock)failBlock;


/**
 异步上传多个文件

 @param url           上传url
 @param params        请求参数
 @param modelArray    model数组
 @param progressBlock 进度回调
 @param successBlock  成功回调
 @param failBlock     失败回调
 @return              上传任务对象
 */
+ (NSURLSessionTask *)uploadWithUrl:(NSString *)url
                             params:(NSDictionary *)params
                     formModelArray:(NSArray <PEPUploadFormModel *>*)modelArray
                      progressBlock:(PEPProgressBlock)progressBlock
                       successBlock:(PEPResponseSuccessBlock)successBlock
                          failBlock:(PEPResponseFailBlock)failBlock;


@end
