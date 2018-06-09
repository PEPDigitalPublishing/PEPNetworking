//
//  PEPViewController.m
//  PEPNetworking
//
//  Created by RavenKite on 05/18/2018.
//  Copyright (c) 2018 RavenKite. All rights reserved.
//

#import "PEPViewController.h"
#import <PEPNetworking/PEPNetworking.h>

@interface PEPViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (nonatomic, strong) PEPDownloadOperation *downlaodOperation;
@end

@implementation PEPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self checkStatus];
//    [self request];
//    [self download];
//    [self upload];
    
}

- (void)checkStatus{
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

- (void)download{
    
    
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
    _downlaodOperation = [PEPDownloadAgent downloadWithDownloadPath:@"https://github.com/NPW-Project/NewPowerCoin/releases/download/v1.0.0.0/npw-1.0.0-osx-high-sierra-only-unsigned.dmg" savePath:savePath progress:^(NSProgress *downloadProgress) {
        _progress.progress = (CGFloat)downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
    } success:^(NSURL *filePath) {
        NSLog(@"%@",filePath);
    } fail:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
    
    _downlaodOperation.statusChangedBlock = ^(PEPDownloadStatus status) {
        NSLog(@"downloadStatusChanged ==== %ld",status);
    };
    
    
    
    //启动
    [_downlaodOperation startDownload];
}
- (IBAction)getAction:(id)sender {
    [self request];
    
}
- (IBAction)postAction:(id)sender {


}




@end
