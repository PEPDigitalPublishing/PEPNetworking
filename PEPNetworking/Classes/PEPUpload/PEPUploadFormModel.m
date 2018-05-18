//
//  PEPUploadFormModel.m
//  PEPNetworking
//
//  Created by Karl on 2018/1/30.
//

#import "PEPUploadFormModel.h"

@implementation PEPUploadFormModel

- (instancetype)initWithLocalPath:(NSString *)localPath localData:(NSData *)localData type:(NSString *)type name:(NSString *)name mimeType:(NSString *)mimeType{
    
    if (self = [super init]) {
        _localPath = localPath;
        _localData = localData;
        _type = type;
        _name = name;
        _mimeType = mimeType;
    }
    
    return self;
}


@end
