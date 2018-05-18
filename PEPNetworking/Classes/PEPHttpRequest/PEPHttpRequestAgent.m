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
static NSTimeInterval   requestTimeout = 20.f;
static NSDictionary *headers;
static NSMutableArray *requestTasksArray;

@interface NSURLRequest (decide)

//判断是否是同一个请求（依据是请求url和参数是否相同）
- (BOOL)isTheSameRequest:(NSURLRequest *)request;

@end


@implementation NSURLRequest (decide)

- (BOOL)isTheSameRequest:(NSURLRequest *)request {
    if ([self.HTTPMethod isEqualToString:request.HTTPMethod]) {
        if ([self.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
            if ([self.HTTPMethod isEqualToString:@"GET"]||[self.HTTPBody isEqualToData:request.HTTPBody]) {
                return YES;
            }
        }
    }
    return NO;
}

@end


@implementation PEPHttpRequestAgent

+ (AFHTTPSessionManager *)manager{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
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

+ (NSMutableArray *)allTasks{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasksArray == nil) {
            requestTasksArray = [[NSMutableArray alloc] init];
        }
    });
    return requestTasksArray;
}

+ (NSURLSessionTask *)getWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    __block NSURLSessionTask *task = nil;
    AFHTTPSessionManager *manager = [self manager];
    
    if (useCache) {
        id responseObj = [[PEPNetworkingCacheManager sharedManager] getCachedResponseObjectWithRequestUrl:url params:params];
        if (responseObj && successBlock) {
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
    
    
    task = [manager GET:url
             parameters:params
               progress:^(NSProgress * _Nonnull downloadProgress) {
                   if (progressBlock) {
                       progressBlock(downloadProgress.completedUnitCount,downloadProgress.totalUnitCount);
                   }
               }
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    if (successBlock) successBlock(responseObject);
                    
                    if (useCache) {
                        [[PEPNetworkingCacheManager sharedManager] cacheResponseObject:responseObject requestUrl:url params:params];
                    }
                    [[self allTasks] removeObject:task];
                }
                failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    if (reachAbilitymanager.status == PEPNetworkStatusNotReachable) {
                        //无网络连接
                        NSError *error = [NSError errorWithDomain:@"com.pepnetwork.networknotreachable" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"暂无网络连接"}];
                        if (failBlock) {
                            failBlock(error);
                        }
                    }else if (failBlock) failBlock(error);
                    
                    [[self allTasks] removeObject:task];
                }];
    if ([self haveSameRequestInTaskArray:task] && !refresh) {
        //有重复请求且不刷新时，使用旧请求
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

+ (NSURLSessionTask *)postWithUrl:(NSString *)url params:(NSDictionary *)params refreshRequest:(BOOL)refresh useCache:(BOOL)useCache progressBlock:(PEPProgressBlock)progressBlock successBlock:(PEPResponseSuccessBlock)successBlock failBlock:(PEPResponseFailBlock)failBlock{
    
    __block NSURLSessionTask *task = nil;
    
    AFHTTPSessionManager *manager = [self manager];
    
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
    task = [manager POST:url
              parameters:params
                progress:^(NSProgress * _Nonnull uploadProgress) {
                    if (progressBlock) {
                        progressBlock(uploadProgress.completedUnitCount,uploadProgress.completedUnitCount);
                    }
                }
                 success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                     if (successBlock) {
                         successBlock(responseObject);
                     }
                     if (useCache) {
                         [[PEPNetworkingCacheManager sharedManager] cacheResponseObject:responseObject requestUrl:url params:params];
                     }
                     [[self allTasks] removeObject:task];
                 } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     if (reachAbilitymanager.status == PEPNetworkStatusNotReachable) {
                         //无网络连接
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

+ (void)configHttpHeader:(NSDictionary *)httpHeader{
    headers = httpHeader;
}

+(void)setTimeout:(NSTimeInterval)timeout{
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


@end

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



