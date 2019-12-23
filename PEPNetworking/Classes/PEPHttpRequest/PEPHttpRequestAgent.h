//
//  PEPNetworking.h
//  PEPNetwork
//
//  Created by Karl on 2017/10/19.
//  Copyright © 2017年 pep.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>


typedef NS_ENUM(NSUInteger, PEPURLRequestSerializerType) {
    PEPURLRequestSerializerTypeHTTP,
    PEPURLRequestSerializerTypeJSON,
    PEPURLRequestSerializerTypePropertyList,
};

typedef NS_ENUM(NSUInteger, PEPURLResponseSerializerType) {
    PEPURLResponseSerializerTypeHTTP,
    PEPURLResponseSerializerTypeJSON,
    PEPURLResponseSerializerTypeXMLParser,
    PEPURLResponseSerializerTypeXMLDocument,
    PEPURLResponseSerializerTypePropertyList,
};


@class AFHTTPSessionManager, AFSecurityPolicy;

typedef void(^PEPProgressBlock) (int64_t completedBytes, int64_t totalBytes);
typedef void(^PEPResponseSuccessBlock) (id response);
typedef void(^PEPResponseFailBlock) (NSError *error);

@interface PEPHttpRequestAgent : NSObject



/// 设置请求和响应Serializer类型
/// @param requestType requestType description
/// @param responseType responseType description
+ (void)configRequestSerializerType:(PEPURLRequestSerializerType)requestType responseSerializerType:(PEPURLResponseSerializerType)responseType;

/**
 批量设置请求头
 
 @param httpHeader 请求头字典
 */
+ (void)configHttpHeader:(NSDictionary *)httpHeader;


/**
 设置超时时间，默认20s(请在调用接口前设置)
 
 @param timeout 请求超时时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;


///// 配置安全策略
///// @param securityPolicy 安全策略对象，可用于进行本地证书校验
//+ (void)configSecurityPolicy:(AFSecurityPolicy *)securityPolicy;


/// 获取HTTPSessionManager
+ (AFHTTPSessionManager *)getAFHTTPSessionManager;


/**
 异步get请求
 
 @param url             请求地址
 @param params          请求参数
 @param refresh         是否刷新请求，是的话，有相同请求会先取消旧请求使用新请求
 @param useCache        是否使用缓存，是的话，先查找本地缓存，并缓存新的数据
 @param progressBlock   进度回调
 @param successBlock    成功回调
 @param failBlock       失败回调
 @return                返回请求任务
 */
+ (NSURLSessionTask *)getWithUrl:(NSString *)url
                          params:(NSDictionary *)params
                  refreshRequest:(BOOL)refresh
                        useCache:(BOOL)useCache
                   progressBlock:(PEPProgressBlock)progressBlock
                    successBlock:(PEPResponseSuccessBlock)successBlock
                       failBlock:(PEPResponseFailBlock)failBlock;


/**
 异步get请求. 使用AFHTTPResponseSerializer类解析
 
 @param url             请求地址
 @param params          请求参数
 @param refresh         是否刷新请求，是的话，有相同请求会先取消旧请求使用新请求
 @param useCache        是否使用缓存，是的话，先查找本地缓存，并缓存新的数据
 @param progressBlock   进度回调
 @param successBlock    成功回调
 @param failBlock       失败回调
 @return                返回请求任务
 */
+ (NSURLSessionTask *)getHTTPResponderWithUrl:(NSString *)url
                                       params:(NSDictionary *)params
                               refreshRequest:(BOOL)refresh
                                     useCache:(BOOL)useCache
                                progressBlock:(PEPProgressBlock)progressBlock
                                 successBlock:(PEPResponseSuccessBlock)successBlock
                                    failBlock:(PEPResponseFailBlock)failBlock;


/**
 异步post请求
 
 @param url             请求地址
 @param params          请求参数
 @param refresh         是否刷新请求，是的话，有相同请求会先取消旧请求使用新请求
 @param useCache        是否使用缓存，是的话，先查找本地缓存，并缓存新的数据
 @param progressBlock   进度回调
 @param successBlock    成功回调
 @param failBlock       失败回调
 @return                返回请求任务
 */
+ (NSURLSessionTask *)postWithUrl:(NSString *)url
                           params:(NSDictionary *)params
                   refreshRequest:(BOOL)refresh
                         useCache:(BOOL)useCache
                    progressBlock:(PEPProgressBlock)progressBlock
                     successBlock:(PEPResponseSuccessBlock)successBlock
                        failBlock:(PEPResponseFailBlock)failBlock;


/**
异步post请求. 使用AFHTTPResponseSerializer类解析

@param url             请求地址
@param params          请求参数
@param refresh         是否刷新请求，是的话，有相同请求会先取消旧请求使用新请求
@param useCache        是否使用缓存，是的话，先查找本地缓存，并缓存新的数据
@param progressBlock   进度回调
@param successBlock    成功回调
@param failBlock       失败回调
@return                返回请求任务
*/
+ (NSURLSessionTask *)postHTTPResponderWithUrl:(NSString *)url
                                       params:(NSDictionary *)params
                                refreshRequest:(BOOL)refresh
                                      useCache:(BOOL)useCache
                                 progressBlock:(PEPProgressBlock)progressBlock
                                  successBlock:(PEPResponseSuccessBlock)successBlock
                                     failBlock:(PEPResponseFailBlock)failBlock;



@end

@interface PEPHttpRequestAgent (cache)

/**
 获取缓存路径
 
 @return 缓存路径
 */
+ (NSString *)getCacheDirectoryPath;

/**
 获取总的缓存大小
 
 @return 缓存大小
 */
+ (NSUInteger)getTotalCachedSize;

/**
 清空所有缓存数据
 */
+ (void)clearCachedData;

@end


