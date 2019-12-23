//
//  PEPViewController.m
//  PEPNetworking
//
//  Created by RavenKite on 05/18/2018.
//  Copyright (c) 2018 RavenKite. All rights reserved.
//

#import "PEPViewController.h"
#import <PEPNetworking/PEPNetworking.h>
#import <AssertMacros.h>


@interface PEPViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (nonatomic, strong) PEPDownloadOperation *downlaodOperation;
@end

@implementation PEPViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self authenticationChallenge];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self checkStatus];
//    [self request];
//    [self download];
//    [self upload];
}

- (void)checkStatus {
    //开启网络状态监听
    [[PEPNetworkReachabilityManager sharedManager] checkNetworkStatus];
    [PEPNetworkReachabilityManager sharedManager].statusChangeBlock = ^(PEPNetworkStatus status) {
        NSLog(@"%ld",status);
    };
}

- (void)request{
    
    NSString *requestString = @"http:/192.168.186.15:8080/jxw-web-new/resuser/shareRes.json";
    NSDictionary *params = @{
                             @"userid":@"03110000000002A021502069051621",
                             @"tbId":@"",
                             @"ex_zynrlx":@"",
                             @"dzwjlx":@"",
                             @"ori_tree_code":@"",
                             @"sch_res_flag":@"",
                             @"pagesize":@"20",
                             @"pageno":@"1"
                             };
    
    [PEPHttpRequestAgent getWithUrl:requestString params:params refreshRequest:NO useCache:NO progressBlock:^(int64_t completedBytes, int64_t totalBytes) {
        
    } successBlock:^(id response) {
        NSLog(@"%@",response);
    } failBlock:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
    
}

- (void)download {
    
}

- (void)upload
{
    
    PEPUploadFormModel *model1 = [[PEPUploadFormModel alloc] initWithLocalPath:@"/Users/renkai/Desktop/test.png"
                                                                     localData:nil
                                                                          type:@"png"
                                                                          name:@"file" mimeType:@"image/png"];
    PEPUploadFormModel *model2 = [[PEPUploadFormModel alloc] initWithLocalPath:@"/Users/renkai/Desktop/timg.jpg"
                                                                     localData:nil
                                                                          type:@"jpg"
                                                                          name:@"file" mimeType:@"image/jpeg"];
    NSArray *modelArray = [NSArray arrayWithObjects:model1,model2,nil];
    
    //单文件
//    [PEPUploadAgent uploadWithUrl:@"http://192.168.189.191:8080/test/uploadFiles.php" params:nil formModel:model1 progressBlcok:^(int64_t completedBytes, int64_t totalBytes) {
//
//    } successBlock:^(id response) {
//        NSLog(@"succss");
//    } failBlock:^(NSError *error) {
//        NSLog(@"error");
//    }];
    
    //多文件
    [PEPUploadAgent uploadWithUrl:@"http://192.168.189.191:8080/test/uploadFiles.php"  params:nil formModelArray:modelArray progressBlock:^(int64_t completedBytes, int64_t totalBytes) {
        
    } successBlock:^(id response) {
        NSLog(@"success");
    } failBlock:^(NSError *error) {
        NSLog(@"error");
    }];
    
    
    
}
- (IBAction)cancelDownlaodAction:(id)sender {
    if (_downlaodOperation) {
        [_downlaodOperation finishDownload];
    }
}
- (IBAction)continueDownloadAction:(id)sender {
    if (_downlaodOperation) {
        [_downlaodOperation startDownload];
    }
    
}
- (IBAction)pauseDownloadAction:(id)sender {
    if (_downlaodOperation) {
        [_downlaodOperation pauseDownload];
    }
    
}
- (IBAction)downloadAction:(id)sender {
    NSString *savePath = [NSString stringWithFormat:@"%@/Library/Caches/textbook.zip",NSHomeDirectory()];
    
    __weak typeof(self) weakself = self;
    self.downlaodOperation = [PEPDownloadAgent downloadWithDownloadPath:@"https://github.com/NPW-Project/NewPowerCoin/releases/download/v1.0.0.0/npw-1.0.0-osx-high-sierra-only-unsigned.dmg" savePath:savePath progress:^(NSProgress *downloadProgress) {
        weakself.progress.progress = (CGFloat)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
    } success:^(NSURL *filePath) {
        NSLog(@"%@",filePath);
    } fail:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
    
    self.downlaodOperation.statusChangedBlock = ^(PEPDownloadStatus status) {
        NSLog(@"downloadStatusChanged ==== %ld",status);
    };
    
    
    //启动
    [self.downlaodOperation startDownload];
}
- (IBAction)getAction:(id)sender {
    [self request];
    
}
- (IBAction)postAction:(id)sender {
    NSString *url = @"https://dianducs.mypep.cn/week/picture.anys";
        
    [PEPHttpRequestAgent postWithUrl:url params:nil refreshRequest:false useCache:false progressBlock:nil successBlock:^(id response) {
        NSLog(@"%@", response[@"list"]);

    } failBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)authenticationChallenge {
    NSString *cerPath = [NSBundle.mainBundle pathForResource:@"domain" ofType:@"cer"];
    NSData *localCertData = [NSData dataWithContentsOfFile:cerPath];
    NSArray *localCertificates = @[localCertData];
    
    AFHTTPSessionManager *manager = [PEPHttpRequestAgent getAFHTTPSessionManager];
    [manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        NSString *host = challenge.protectionSpace.host;

        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        *credential = cre;
        
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] == false) {
            return disposition;
        }

        // AFN默认的校验方式
//        if ([[PEPHttpRequestAgent getAFHTTPSessionManager].securityPolicy evaluateServerTrust:serverTrust forDomain:host]) {
//            disposition = NSURLSessionAuthChallengeUseCredential;
//        }
            
        // 域名校验
        NSMutableArray *policies = [NSMutableArray array];
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)host)];
        OSStatus status = SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
        if (status != 0) {
            NSLog(@"域名校验失败(%d)", (int)status);
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }

        BOOL isValid = PEPServerTrustIsValid(serverTrust);
        
        if (isValid == false) {
            NSLog(@"服务端证书无效");
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        } else {
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in localCertificates) {
                [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
            }
            
            status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);
            if (status != 0) {
                NSLog(@"本地证书存在错误(%d)", (int)status);
                return NSURLSessionAuthChallengePerformDefaultHandling;
            }

            NSArray<NSData *> *serverCertificates = PEPCertificateTrustChainForServerTrust(serverTrust);
            for (NSData *trustChainCertificate in serverCertificates.reverseObjectEnumerator) {
                if ([localCertificates containsObject:trustChainCertificate]) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                    break;
                }
            }
            
            if (disposition != NSURLSessionAuthChallengeUseCredential) {
                NSLog(@"服务端证书与本地证书不匹配");
            } else {
                NSLog(@"证书校验通过");
            }
        }

        return disposition;
    }];
}


// 校验服务端证书有效性
static BOOL PEPServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
    
    /**
     kSecTrustResultUnspecified 证书有效，但用户并未明确声明信任该证书。
     kSecTrustResultProceed 证书有效，且用户明确声明信任该证书。
     */
    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

_out:
    return isValid;
}

static NSArray * PEPCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];

    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
        
        // 证书摘要信息
        NSString *subjectSummaryLocal = (__bridge_transfer NSString *)SecCertificateCopySubjectSummary(certificate);
        NSLog(@"证书摘要：%@", subjectSummaryLocal);
    }

    return [NSArray arrayWithArray:trustChain];
}




@end
