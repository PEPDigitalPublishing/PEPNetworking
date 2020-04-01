//
//  PEPUploadAgent.m
//  PEPNetworking
//
//  Created by Karl on 2018/1/30.
//

#import "PEPUploadAgent.h"
#import <AFNetworking/AFNetworking.h>
#import "PEPNetworkReachabilityManager.h"

static NSMutableArray *requestTasksArray;

//@interface NSURLRequest (decide)
//
////判断是否是同一个请求（依据是请求url和参数是否相同）
//- (BOOL)isTheSameRequest:(NSURLRequest *)request;
//
//@end
//
//@implementation NSURLRequest (decide)
//
//- (BOOL)isTheSameRequest:(NSURLRequest *)request {
//    if ([self.HTTPMethod isEqualToString:request.HTTPMethod]) {
//        if ([self.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
//            if ([self.HTTPMethod isEqualToString:@"GET"]||[self.HTTPBody isEqualToData:request.HTTPBody]) {
//                return YES;
//            }
//        }
//    }
//    return NO;
//}
//@end

@implementation PEPUploadAgent



+ (AFHTTPSessionManager *)manager{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = 20;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[
                                                                              @"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*",
                                                                              @"application/octet-stream",
                                                                              @"application/zip"
                                                                              ]];
    return manager;
}

+ (NSURLSessionTask *)uploadWithUrl:(NSString *)url params:(NSDictionary *)params formModel:(PEPUploadFormModel *)model progressBlcok:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    
    AFHTTPSessionManager *manager = [self manager];
    //检测网络环境
    PEPNetworkReachabilityManager *reachManager = [PEPNetworkReachabilityManager sharedManager];
    [reachManager checkNetworkStatus];
    if (reachManager.status == PEPNetworkStatusNotReachable) {
        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
        if (failBlock) {
            failBlock(error);
        }
        return nil;
    }
    NSURLSessionTask *task = [manager POST:url parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *data = nil;
        if (model.localData) {
            data = model.localData;
        }else {
            data = [NSData dataWithContentsOfFile:model.localPath];
        }
        NSString *fileName = nil;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmssSSS";
        NSString *day = [formatter stringFromDate:[NSDate date]];
        fileName = [NSString stringWithFormat:@"%@.%@",day,model.type];
        [formData appendPartWithFileData:data
                                    name:model.name
                                fileName:fileName
                                mimeType:model.mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) {
            failBlock(error);
        }
    }];
    
    [task resume];
    return task;
}

+ (NSURLSessionTask *)uploadWithUrl:(NSString *)url params:(NSDictionary *)params formModelArray:(NSArray<PEPUploadFormModel *> *)modelArray progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    AFHTTPSessionManager *manager = [self manager];
    
    //检测网络环境
    PEPNetworkReachabilityManager *reachManager = [PEPNetworkReachabilityManager sharedManager];
    [reachManager checkNetworkStatus];
    if (reachManager.status == PEPNetworkStatusNotReachable) {
        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
        if (failBlock) {
            failBlock(error);
        }
        return nil;
    }

    NSURLSessionTask *task = [manager POST:url parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [modelArray enumerateObjectsUsingBlock:^(PEPUploadFormModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *data = nil;
            if (model.localData) {
                data = model.localData;
            }else {
                data = [NSData dataWithContentsOfFile:model.localPath];
            }
            NSString *fileName = nil;
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *day = [formatter stringFromDate:[NSDate date]];
            fileName = [NSString stringWithFormat:@"%@.%@",day,model.type];
            [formData appendPartWithFileData:data
                                        name:model.name
                                    fileName:fileName
                                    mimeType:model.mimeType];
            
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) {
            failBlock(error);
        }
    }];
    
    [task resume];
    return task;
    
}


@end
