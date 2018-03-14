//
//  IwiteksPanoramaViewController.m
//  PalmarTourism
//
//  Created by 徐凯 on 2018/2/28.
//  Copyright © 2018年 贵州中测. All rights reserved.
//

#import "PanoramaViewController.h"
// 导入google全景图
#import "GVRPanoramaView.h"
// 导入AFNetWorking网络框架
#import "AFNetworking.h"
// 导入进度动画
#import "FeHourGlass.h"

// 宏定义屏幕宽高
#define SCREEN_WIDTH self.view.frame.size.width
#define SCREEN_HEIGHT self.view.frame.size.height

// 宏定义16进制颜色
#define UIColorFromHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s & 0xFF00) >> 8))/255.0 blue:((s & 0xFF))/255.0  alpha:1.0]

// 宏定义判断是否为IphoneX
#define KIsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

@interface PanoramaViewController ()

@property (nonatomic, weak) GVRPanoramaView *panoramaView;

@property (nonatomic, strong) UIImage *vrimg;

// 对话框Action
@property (strong, nonatomic) UIAlertAction *okAction;
@property (strong, nonatomic) UIAlertAction *cancelAction;

// 进度View
@property (nonatomic, strong) FeHourGlass *hourGlass;
@property (nonatomic, strong) UILabel *label;
// 取消下载View
@property (nonatomic, strong) UIButton *cancelBtn;

/** AFNetworking断点下载（支持离线）需用到的属性 **********/
/** 文件的总长度 */
@property (nonatomic, assign) NSInteger fileLength;
/** 当前下载长度 */
@property (nonatomic, assign) NSInteger currentLength;
/** 文件句柄对象 */
@property (nonatomic, strong) NSFileHandle *fileHandle;
/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDataTask *downloadTask;
/* AFURLSessionManager */
@property (nonatomic, strong) AFURLSessionManager *manager;

// 全景图下载地址
@property (nonatomic, strong) NSString *panoramaUrl;
// 全景图名称
@property (nonatomic, strong) NSString *panoramaImgName;

// 关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;

// 关闭按钮图片
@property (nonatomic, strong) UIImage *closeBtnImage;

@end

@implementation PanoramaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 添加VR全景图通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showVRPanorama:) name:@"showVRPanorama" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 加载全景图
- (void)loadPanoramaView{
    GVRPanoramaView *panoramaView = [[GVRPanoramaView alloc] init];
    panoramaView.enableFullscreenButton = NO;
    panoramaView.enableCardboardButton = NO;
    panoramaView.enableInfoButton=NO;
    panoramaView.enableTouchTracking = YES;
    panoramaView.frame = CGRectMake(0,0,SCREEN_WIDTH,SCREEN_HEIGHT);
    [self.view addSubview:panoramaView];
    // 添加关闭按钮
    [self loadCloseButton];
    //    [imageView loadImage:[UIImage imageNamed:@"andes"]];
    [panoramaView loadImage:self.vrimg];
    self.panoramaView = panoramaView;
}

- (void)StartDownLoadImage{
    // 沙盒文件路径
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.panoramaImgName];
    
    NSInteger currentLength = [self fileLengthForPath:path];
    if (currentLength > 0) {  // [继续下载]
        self.currentLength = currentLength;
    }
    [self.downloadTask resume];
}

#pragma mark - 下载 - 断点续传
// 下载网络图片
- (NSURLSessionDataTask *)downloadTask{
    if (!_downloadTask) {
        NSURL *URL = [NSURL URLWithString:self.panoramaUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        // 设置HTTP请求头中的Range
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.currentLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        __weak typeof(self) weakSelf = self;
        NSProgress *downloadProgress = nil;
        _downloadTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error){
            // 清空长度
            weakSelf.currentLength = 0;
            weakSelf.fileLength = 0;
            // 关闭fileHandle
            [weakSelf.fileHandle closeFile];
            weakSelf.fileHandle = nil;
            [self loadImage];
            [self loadPanoramaView];
            self.panoramaView.alpha = 0;
            [UIView animateWithDuration:2.0 animations:^{
                self.hourGlass.alpha = 0;
                self.cancelBtn.alpha = 0;
                self.panoramaView.alpha = 1;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self.hourGlass removeFromSuperview];
                    [self.cancelBtn removeFromSuperview];
                }
            }];
        }];
        
        // 开始接口文件调用
        [self.manager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
            // 获得下载文件的总长度：请求下载的文件长度 + 当前已经下载的文件长度
            weakSelf.fileLength = response.expectedContentLength + self.currentLength;
            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            if (!response.expectedContentLength) {
                weakSelf.currentLength = 0;
                weakSelf.fileLength = 0;
                [weakSelf.fileHandle closeFile];
                weakSelf.fileHandle = nil;
                [mainQueue addOperationWithBlock:^{
                    self.label.text = [NSString stringWithFormat:@"100.00%%"];
                    [self loadImage];
                    [self loadPanoramaView];
                    self.panoramaView.alpha = 0;
                    [UIView animateWithDuration:1.5 animations:^{
                        self.hourGlass.alpha = 0;
                        self.cancelBtn.alpha = 0;
                        self.panoramaView.alpha = 1;
                    } completion:^(BOOL finished) {
                        if (finished) {
                            [self.hourGlass removeFromSuperview];
                            [self.cancelBtn removeFromSuperview];
                            
                        }
                    }];
                }];
                return _downloadTask;
            }else{
                [mainQueue addOperationWithBlock:^{
                    [self setupProgressView];
                    [self judgeNetStatus];
                }];
            }
            // 沙盒文件路径
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.panoramaImgName];
            
            // 创建一个空的文件到沙盒中
            NSFileManager *manager = [NSFileManager defaultManager];
            
            if (![manager fileExistsAtPath:path]) {
                // 如果没有下载文件的话，就创建一个文件。如果有下载文件的话，则不用重新创建(不然会覆盖掉之前的文件)
                [manager createFileAtPath:path contents:nil attributes:nil];
            }
            
            // 创建文件句柄
            weakSelf.fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
            
            // 允许处理服务器的响应，才会继续接收服务器返回的数据
            return NSURLSessionResponseAllow;
        }];
        
        // 下载进度调用
        [self.manager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            
            // 指定数据的写入位置 -- 文件内容的最后面
            [weakSelf.fileHandle seekToEndOfFile];
            
            // 向沙盒写入数据
            [weakSelf.fileHandle writeData:data];
            
            // 拼接文件总长度
            weakSelf.currentLength += data.length;
            
            // 获取主线程，不然无法正确显示进度。
            NSOperationQueue* mainQueue = [NSOperationQueue mainQueue];
            [mainQueue addOperationWithBlock:^{
                [self.hourGlass show];
                // 下载进度
                if (weakSelf.fileLength == 0) {
                    self.label.text = [NSString stringWithFormat:@"00.00%%"];
                } else {
                    self.label.text = [NSString stringWithFormat:@"%.2f%%",100.0 * weakSelf.currentLength / weakSelf.fileLength];
                }
                
            }];
        }];
    }
    return _downloadTask;
}

/**
 * 获取已下载的文件大小
 */
- (NSInteger)fileLengthForPath:(NSString *)path {
    NSInteger fileLength = 0;
    NSFileManager *fileManager = [[NSFileManager alloc] init]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileLength = [fileDict fileSize];
        }
    }
    return fileLength;
}

/**
 * manager的懒加载
 */
- (AFURLSessionManager *)manager {
    if (!_manager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 1. 创建会话管理者
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return _manager;
}

//加载本地图片
- (void)loadImage{
    //借助以上获取的沙盒路径读取图片
//    NSString *path=[NSString stringWithFormat:@"%@/Documents/%@",NSHomeDirectory(),self.panoramaImgName];
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.panoramaImgName];
    self.vrimg =[[UIImage alloc]initWithContentsOfFile:path];
}

// 判断网络状态
- (void)judgeNetStatus{
     [self.downloadTask suspend];
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    // 提示：要监控网络连接状态，必须要先调用单例的startMonitoring方法
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == -1) {
            NSLog(@"未识别网络");
        }
        if (status == 0) {
            NSLog(@"未连接网络");
        }
        if (status == 1) {
            NSLog(@"3G/4G网络");
            // 初始化对话框
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"图片较大,当前使用3G/4G网络,确定继续查看吗?" preferredStyle:UIAlertControllerStyleAlert];
            // 继续下载
            _okAction = [UIAlertAction actionWithTitle:@"流量多,任性" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {
                 [self StartDownLoadImage];
            }];
            _cancelAction =[UIAlertAction actionWithTitle:@"伤不起,算了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                [self closeVC];
            }];
            [alert addAction:_cancelAction];
            [alert addAction:_okAction];
            // 取消
            [self presentViewController:alert animated:true completion:nil];
        }
        if (status == 2) {
            NSLog(@"Wifi网络");
            // 下载图片
            [self StartDownLoadImage];
        }
    }];
}

-(void)setupProgressView{
    CGFloat progressRadius = 150.0f;
    // 添加加载动画
    _hourGlass = [[FeHourGlass alloc] initWithView:self.view];
    [self.view addSubview:_hourGlass];
    // 添加取消下载按钮
    UIButton *cancelButton = [[UIButton alloc] init];
    [cancelButton setTitle:@"取消下载" forState:(UIControlStateNormal)];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize: 13.0];
    // 设置button边框
    cancelButton.layer.cornerRadius = 10.0;//2.0是圆角的弧度，根据需求自己更改
    cancelButton.layer.borderWidth = 1.0f;//设置边框颜色
    //设置按钮的边界颜色
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGColorRef color = CGColorCreate(colorSpaceRef, (CGFloat[]){1,1,1,1});
    [cancelButton.layer setBorderColor:color];
    cancelButton.frame = CGRectMake((SCREEN_WIDTH-85) / 2, (SCREEN_HEIGHT / 2) + progressRadius / 2 - 5, 85, 30);
    [cancelButton addTarget:nil action:@selector(btnCancelDownload) forControlEvents:UIControlEventTouchUpInside];
    self.cancelBtn = cancelButton;
    [self.view addSubview:cancelButton];
    _label = [[UILabel alloc] init];
    _label.text = @"00.00%";
    [_label setFont:[UIFont systemFontOfSize: 13.0]];
    CGSize labelSize = [_label.text sizeWithFont:_label.font
                               constrainedToSize:CGSizeMake(FLT_MAX,FLT_MAX)
                                   lineBreakMode:UILineBreakModeWordWrap];
    _label.frame = CGRectMake((SCREEN_WIDTH-labelSize.width) / 2 + 2, (SCREEN_HEIGHT / 2) + progressRadius / 2 - 45, 85, 30);
    _label.textColor = UIColorFromHex(0xffffff);
    [self.view addSubview:_label];

//    [_hourGlass showWhileExecutingBlock:^{
//        [self myTask];
//    } completion:^{
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    }];
}

-(void)loadCloseButton{
    if(KIsiPhoneX){
       _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60,54, 30, 30)];
    }else{
      _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, 20, 30, 30)];
    }
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *imagePath = [resourcePath stringByAppendingPathComponent:@"closePanorama.png"];
    //创建图片
    self.closeBtnImage = [UIImage imageWithContentsOfFile:imagePath];
    [_closeBtn setBackgroundImage:self.closeBtnImage forState:UIControlStateNormal];
    [_closeBtn addTarget:nil action:@selector(closeVC) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview:_closeBtn];
}

// 关闭当前控制器
-(void)closeVC{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showVRPanorama" object:nil];
    [self.downloadTask suspend];
//    [self.downloadTask cancel];
    [self.label removeFromSuperview];
    self.label = nil;
    [self.hourGlass removeFromSuperview];
    self.hourGlass = nil;
    [self.cancelBtn removeFromSuperview];
    self.cancelBtn = nil;
    [self.panoramaView loadImage:nil];
    self.downloadTask = nil;
    self.panoramaView = nil;
    self.vrimg = nil;
    [self.closeBtn setBackgroundImage:nil forState:UIControlStateNormal];
    [self.closeBtn removeFromSuperview];
    self.closeBtn = nil;
    self.closeBtnImage = nil;
    [self removeFromParentViewController];
//    [self.vrimg retainCount];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 取消下载按钮
-(void)btnCancelDownload{
    [self closeVC];
}

//显示VR全景图
- (void)showVRPanorama:(NSNotification *)noti
{
    self.panoramaUrl = [noti object];
    NSArray *strArray = [self.panoramaUrl componentsSeparatedByString:@"/"];
    NSInteger nameIndex = [strArray count] - 1;
    self.panoramaImgName = strArray[nameIndex];
    [self StartDownLoadImage];
//    [self loadImage];
}
@end
