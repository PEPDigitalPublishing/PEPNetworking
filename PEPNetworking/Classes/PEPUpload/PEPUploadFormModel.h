//
//  PEPUploadFormModel.h
//  PEPNetworking
//
//  Created by Karl on 2018/1/30.
//

#import <Foundation/Foundation.h>

@interface PEPUploadFormModel : NSObject

/**
 文件本地路径，和localData二选一即可，优先使用localData
 */
@property (nonatomic, copy) NSString *localPath;

/**
 文件二进制数据，和localPath二选一即可，优先使用data
 */
@property (nonatomic, strong) NSData *localData;

/**
 文件类型， "png"、"pdf"等
 */
@property (nonatomic, copy) NSString *type;

/**
 服务端给出的接受字段名
 */
@property (nonatomic, copy) NSString *name;

/**
 mimeType
 */
@property (nonatomic, copy) NSString *mimeType;

- (instancetype)initWithLocalPath:(NSString *)localPath localData:(NSData *)localData type:(NSString *)type name:(NSString *)name mimeType:(NSString *)mimeType;
@end
