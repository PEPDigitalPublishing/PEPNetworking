//
//  PEPNetworking.m
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import "PEPHttpRequestAgent.h"
#import "PEPNetworkingCacheManager.h"
#import "PEPNetworkReachabilityManager.h"
#import <AFNetworking/AFNetworking.h>
#import <PEPBigData/PEPBigData.h>

static NSTimeInterval   requestTimeout = 20.f;
static NSDictionary     *headers;
static NSMutableArray   *requestTasksArray;


// MARK: - NSURLRequest + Decide
// MARK: -

@interface NSURLRequest (decide)

//判断是否是同一个请求（依据是请求url和参数是否相同）
- (BOOL)isTheSameRequest:(NSURLRequest *)request;

@end


@implementation NSURLRequest (decide)

- (BOOL)isTheSameRequest:(NSURLRequest *)request {
    if ([self.HTTPMethod isEqualToString:request.HTTPMethod]) {
        if ([self.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
            if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPBody isEqualToData:request.HTTPBody]) {
                return YES;
            }
        }
    }
    return NO;
}

@end


// MARK: - PEPHttpRequestAgent
// MARK: -


@implementation PEPHttpRequestAgent

// MARK: - Properties

+ (AFHTTPSessionManager *)manager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    [serializer setRemovesKeysWithNullValues: NO];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    manager.requestSerializer.timeoutInterval = requestTimeout;
    //设置请求头
    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
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
    //开启网络状态监测
    [[PEPNetworkReachabilityManager sharedManager] checkNetworkStatus];
    //检测缓存内存大小
    [[PEPNetworkingCacheManager sharedManager] clearLRUCache];
    return manager;
}

+ (AFHTTPSessionManager *)httpResponderManager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    manager.requestSerializer.timeoutInterval = requestTimeout;
    
    // 设置请求头
    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
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
    //开启网络状态监测
    [[PEPNetworkReachabilityManager sharedManager] checkNetworkStatus];
    //检测缓存内存大小
    [[PEPNetworkingCacheManager sharedManager] clearLRUCache];
    return manager;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasksArray == nil) {
            requestTasksArray = [[NSMutableArray alloc] init];
        }
    });
    return requestTasksArray;
}


// MARK: - GET

+ (NSURLSessionTask *)getWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    return [self getWithUrl:url params:params refreshRequest:refresh useCache:useCache progressBlock:progressBlock successBlock:successBlock failBlock:failBlock isHttpResponder:false];
}

+ (NSURLSessionTask *)getHTTPResponderWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock {
    return [self getWithUrl:url params:params refreshRequest:refresh useCache:useCache progressBlock:progressBlock successBlock:successBlock failBlock:failBlock isHttpResponder:true];
}

+ (NSURLSessionTask *)getWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock isHttpResponder:(BOOL)isHttpResponder {
    __block NSURLSessionTask *task = nil;
    
    AFHTTPSessionManager *manager = isHttpResponder ? [self httpResponderManager] : [self manager];
    
    if (useCache) {
        id responseObj = [[PEPNetworkingCacheManager sharedManager] getCachedResponseObjectWithRequestUrl:url params:params];
        if (responseObj && successBlock) {
            successBlock(responseObj);
        }
    }
    
    PEPNetworkReachabilityManager *reachAbilitymanager = [PEPNetworkReachabilityManager sharedManager];
    if (reachAbilitymanager.status == PEPNetworkStatusNotReachable && !useCache) {
        // 无网络连接且不使用缓存
        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
        if (failBlock) {
            failBlock(error);
        }
        return nil;
    }
    
    NSTimeInterval begin = NSDate.date.timeIntervalSince1970 * 1000;
    task = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        
       if (progressBlock) {
           progressBlock(downloadProgress.completedUnitCount,downloadProgress.totalUnitCount);
       }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 异常响应埋点
        [self onEventFromExceptionWithTask:task params:params response:responseObject beginTimestamp:begin];

        if (successBlock) successBlock(responseObject);
        
        if (useCache) {
            [[PEPNetworkingCacheManager sharedManager] cacheResponseObject:responseObject requestUrl:url params:params];
        }
        [[self allTasks] removeObject:task];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // 异常响应埋点
        if (error.code != -999) {   // -999 取消请求，不算异常响应
            NSString *codeString = [self codeStringFromFailedResponseWithError:error task:task];
            
            [self onEventFromExceptionWithRequestURL:url params:params retCode:codeString retInfo:error.debugDescription beginTimestamp:begin endTimestamp:NSDate.date.timeIntervalSince1970 * 1000 object:nil];
        }
        
        if (reachAbilitymanager.status == PEPNetworkStatusNotReachable) {
            // 无网络连接
            NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
            if (failBlock) {
                failBlock(error);
            }
        } else if (failBlock) failBlock(error);
        
        [[self allTasks] removeObject:task];
    }];
    
    if ([self haveSameRequestInTaskArray:task] && !refresh) {
        // 有重复请求且不刷新时，使用旧请求
        [task cancel];
        return task;
    } else {
        NSURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:task];
        if (oldTask) {
            [[self allTasks] removeObject:oldTask];
        }
        if (task) {
            [[self allTasks] addObject:task];
        }
        [task resume];
    }
    
    return task;
}


// MARK: - POST


+ (NSURLSessionTask *)postWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    
    return [self postWithUrl:url params:params refreshRequest:refresh useCache:useCache progressBlock:progressBlock successBlock:successBlock failBlock:failBlock isHttpResponder:false];
}

+ (NSURLSessionTask *)postHTTPResponderWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock {
    return [self postWithUrl:url params:params refreshRequest:refresh useCache:useCache progressBlock:progressBlock successBlock:successBlock failBlock:failBlock isHttpResponder:true];
}

+ (NSURLSessionTask *)postWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock isHttpResponder:(BOOL)isHttpResponder {
    __block NSURLSessionTask *task = nil;
    
    AFHTTPSessionManager *manager = isHttpResponder ? [self httpResponderManager] : [self manager];

    id responseObj = [[PEPNetworkingCacheManager sharedManager] getCachedResponseObjectWithRequestUrl:url params:params];
    if (responseObj && useCache) {
        if (successBlock) {
            successBlock(responseObj);
        }
    }
    
    PEPNetworkReachabilityManager *reachAbilitymanager = [PEPNetworkReachabilityManager sharedManager];
    if (reachAbilitymanager.status == PEPNetworkStatusNotReachable && !useCache) {
        //无网络连接且不使用缓存
        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
        if (failBlock) {
            failBlock(error);
        }
        return nil;
    }
    
    
    NSTimeInterval begin = NSDate.date.timeIntervalSince1970 * 1000;
    task = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress.completedUnitCount,uploadProgress.completedUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 异常响应埋点
        [self onEventFromExceptionWithTask:task params:params response:responseObject beginTimestamp:begin];
        
        if (successBlock) {
            successBlock(responseObject);
        }
        if (useCache) {
            [[PEPNetworkingCacheManager sharedManager] cacheResponseObject:responseObject requestUrl:url params:params];
        }
        [[self allTasks] removeObject:task];
        
     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         
         // 异常响应埋点
         if (error.code != -999) {   // -999 取消请求，不算异常响应
             NSString *codeString = [self codeStringFromFailedResponseWithError:error task:task];
             
             [self onEventFromExceptionWithRequestURL:url params:params retCode:codeString retInfo:error.debugDescription beginTimestamp:begin endTimestamp:NSDate.date.timeIntervalSince1970 * 1000 object:nil];
         }
         
         if (reachAbilitymanager.status == PEPNetworkStatusNotReachable) {
             // 无网络连接
             NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
             if (failBlock) {
                 failBlock(error);
             }
         }else if (failBlock) failBlock(error);
         [[self allTasks] removeObject:task];
                     
     }];
    
    if ([self haveSameRequestInTaskArray:task] && !refresh) {
        [task cancel];
        return task;
    } else {
        NSURLSessionTask *oldTask = [self cancleSameRequestInTasksPool:task];
        if (oldTask) {
            [[self allTasks] removeObject:oldTask];
        }
        if (task) {
            [[self allTasks] addObject:task];
            [task resume];
            return task;
        }
    }
    return nil;
}



// MARK: - Other

+ (void)configHttpHeader:(NSDictionary *)httpHeader{
    headers = httpHeader;
}

+ (void)setTimeout:(NSTimeInterval)timeout{
    requestTimeout = timeout;
}

+ (BOOL)haveSameRequestInTaskArray:(NSURLSessionTask *)task{
    __block BOOL isSame = NO;
    
    [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.originalRequest isTheSameRequest:task.originalRequest]) {
            isSame = YES;
            *stop = YES;
        }
    }];
    return isSame;
}

+ (NSURLSessionTask *)cancleSameRequestInTasksPool:(NSURLSessionTask *)task {
    __block NSURLSessionTask *oldTask = nil;
    
    [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([task.originalRequest isTheSameRequest:obj.originalRequest]) {
            if (obj.state == NSURLSessionTaskStateRunning) {
                [obj cancel];
                oldTask = obj;
            }
            *stop = YES;
        }
    }];
    
    return oldTask;
}


// MARK: - 埋点

+ (NSString *)codeStringFromFailedResponseWithError:(NSError *)error task:(NSURLSessionDataTask *)task {
    NSInteger errorCode = error.code;
    NSInteger statusCode = 0;
    if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
        statusCode = [(NSHTTPURLResponse *)task.response statusCode];
    }
    
    return [self codeStringWithErrorCode:errorCode httpStatusCode:statusCode];
}


+ (NSString *)codeStringWithErrorCode:(NSInteger)errorCode httpStatusCode:(NSInteger)statuCode {
    return [NSString stringWithFormat:@"errcode:%ld,http_status_code:%ld", (long)errorCode, (long)statuCode];
}

+ (NSString *)originURLStringWithTask:(NSURLSessionDataTask *)task {
    NSURL *URL = task.currentRequest.URL;
    NSString *query = [NSString stringWithFormat:@"?%@", URL.query];
    NSString *url = [URL.absoluteString stringByReplacingOccurrencesOfString:query withString:@""];

    return url;
}

+ (void)onEventFromExceptionWithTask:(NSURLSessionDataTask *)task params:(NSString *)params response:(id)responseObject beginTimestamp:(NSTimeInterval)begin {
    NSString *url = [self originURLStringWithTask:task];
    
    if ([responseObject isKindOfClass:NSDictionary.class] && [[(NSDictionary *)responseObject allKeys] containsObject:@"errcode"]) {
        NSInteger errorCode = [responseObject[@"errcode"] integerValue];
        
        if (errorCode != 110) {
            NSInteger statusCode = 0;
            if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
                statusCode = [(NSHTTPURLResponse *)task.response statusCode];
            }
            
            NSString *codeString = [self codeStringWithErrorCode:errorCode httpStatusCode:statusCode];
            
            [self onEventFromExceptionWithRequestURL:url params:params retCode:codeString retInfo:responseObject[@"errmsg"] beginTimestamp:begin endTimestamp:NSDate.date.timeIntervalSince1970 * 1000 object:nil];
        }
        
    } else if ([responseObject isKindOfClass:NSArray.class] && [(NSArray *)responseObject count] > 0) {
        id tmp = [(NSArray *)responseObject firstObject];
        
        if ([tmp isKindOfClass:NSDictionary.class] && [[(NSDictionary *)tmp allKeys] containsObject:@"errcode"]) {
            NSInteger errorCode = [tmp[@"errcode"] integerValue];

            if (errorCode != 110) {
                NSInteger statusCode = errorCode;
                if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
                    statusCode = [(NSHTTPURLResponse *)task.response statusCode];
                }
                
                NSString *codeString = [self codeStringWithErrorCode:errorCode httpStatusCode:statusCode];
                
                [self onEventFromExceptionWithRequestURL:url params:params retCode:codeString retInfo:responseObject[@"errmsg"] beginTimestamp:begin endTimestamp:NSDate.date.timeIntervalSince1970 * 1000 object:nil];
            }
        }
    }
}

+ (void)onEventFromExceptionWithRequestURL:(NSString *)requestURL
                                    params:(NSDictionary *)params
                                   retCode:(NSString *)retCode
                                   retInfo:(NSString *)retInfo
                            beginTimestamp:(NSTimeInterval)begin
                              endTimestamp:(NSTimeInterval)end
                                    object:(NSString *)object {
    NSString *paramsStr = @"";
    if (params != nil) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
        paramsStr = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
        paramsStr = [self handleStr:paramsStr];
    }
    
    retInfo = [self handleStr:retInfo];
    
    [PEPLogPortManager.shareInstance onEventFromExceptionWithActionID:@"sys_400003" actionType:nil requestURL:requestURL params:paramsStr retCode:retCode retInfo:retInfo beginTimestamp:begin endTimestamp:end object:object fromPos:nil];
}

+ (NSString *)handleStr:(NSString *)str {
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"~" withString:@""];
    
    return str;
}



@end



// MARK: - PEPHttpRequestAgent+Cache
// MARK: -


@implementation PEPHttpRequestAgent (cache)

+ (NSString *)getCacheDirectoryPath{
    return [[PEPNetworkingCacheManager sharedManager] getCacheDiretoryPath];
}

+ (NSUInteger)getTotalCachedSize{
    return [[PEPNetworkingCacheManager sharedManager] totalCachedSize];
}

+ (void)clearCachedData{
    [[PEPNetworkingCacheManager sharedManager] clearTotalCache];
}

@end



