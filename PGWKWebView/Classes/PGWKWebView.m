//
//  PGWKWebView.m purepgmr的WKWebView Simple useful webview base on WKWebView
//  PGWKWebView
//
//  Created by 徐凯 on 02/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import "PGWKWebView.h"
// 导入文件读取工具类
#import "FileTools.h"
// 导入微信Api
#import "WXApi.h"
// 导入支付宝SDK
#import "AlipaySDK/AlipaySDK.h"
// 引入讯飞语音
#import "IFlyMSC/IFlyMSC.h"
// 导入讯飞数据解析工具
#import "ISRDataHelper.h"
// 导入苹果地图
#import <MapKit/MapKit.h>
// 导入VRController
#import "PanoramaViewController.h"


// 添加微信代理协议
@interface PGWKWebView() <WXApiDelegate>

@property (nonatomic, strong) UIViewController *controller;

@property (nonatomic, strong) NSDictionary *configDict;

// 语音合成对象
@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;

// 不带界面的语音识别对象
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;

// 语音识别结果
@property (nonatomic, strong) NSString *recognizerResult;

@end

@implementation PGWKWebView

#pragma mark - init
- (id)initWithFrame:(CGRect)frame target:(nullable id)target{
    // 读取本地配置文件
    _configDict = [FileTools readLocalFileWithName:@"PGConfig"];
    if (_configDict == nil) {
        NSLog(@"缺少配置文件或配置文件有误");
    }
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 创建UserContentController（提供JavaScript向webView发送消息的方法）
    WKUserContentController* userContent = [[WKUserContentController alloc] init];
    // 添加消息处理，注意：self指代的对象需要遵守WKScriptMessageHandler协议，结束时需要移除
    [userContent addScriptMessageHandler:self name:@"NativeMethod"];
    // 将UserConttentController设置到配置文件
    config.userContentController = userContent;
    self = [super initWithFrame:frame configuration:config];
    _controller = target;
    if (self) {
        self.navigationDelegate = self;
        self.UIDelegate = self;
    }
    [self initNotification];
    // 初始化讯飞语音合成
    [self initIflyCompound];
    // 初始化讯飞语音识别
    [self initIflyDiscern];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    return self;
}


#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"xukai --- didStartProvisionalNavigation");
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"xukai --- didCommitNavigation");
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"xukai --- didFinishNavigation");
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"xukai --- didFailProvisionalNavigation");
}

// 处理拨打电话以及Url跳转等等
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    NSString *scheme = [URL scheme];
    if ([scheme isEqualToString:@"tel"]) {
        NSString *resourceSpecifier = [URL resourceSpecifier];
        NSString *callPhone = [NSString stringWithFormat:@"telprompt://%@", resourceSpecifier];
        /// 防止iOS 10及其之后，拨打电话系统弹出框延迟出现
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callPhone]];
        });
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [_controller presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [_controller presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    [_controller presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - js调用oc方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *dataDic = message.body;
        // 判断是否是调用原生的方法
        if ([@"NativeMethod" isEqualToString:message.name]) {
            if ([dataDic[@"methodName"] isEqualToString:@"wechatLogin"]) {
                if (_configDict[@"wechat"] != nil) {
                    if(_configDict[@"wechat"][@"AppID"] != nil){
                        if(_configDict[@"wechat"][@"AppSecret"] != nil){
                            SendAuthReq *req = [[SendAuthReq alloc]init];
                            req.scope = @"snsapi_userinfo";
                            req.state = @"123";
                            [WXApi sendReq:req];
                        }else{
                            NSLog(@"缺少微信AppSecret配置");
                        }
                    }else{
                        NSLog(@"缺少微信AppID配置");
                    }
                }else{
                    NSLog(@"缺少微信配置");
                }
            }
            else if([dataDic[@"methodName"] isEqualToString:@"alipay"]){
                [self aliPay:dataDic[@"outTradeNo"]];
            }
            // 查询用户是否安装了微信
            if([dataDic[@"methodName"] isEqualToString:@"hasWechat"]) {
                if ([WXApi isWXAppInstalled]) {
                    [self evaluateJavaScript:@"_Native_hasWechat(true)" completionHandler:^(id item, NSError * _Nullable error) {
                        // Block中处理是否通过了或者执行JS错误的代码
                        NSLog(@"%@",error);
                    }];
                }else{
                    [self evaluateJavaScript:@"_Native_hasWechat(false)" completionHandler:^(id item, NSError * _Nullable error) {
                        // Block中处理是否通过了或者执行JS错误的代码
                        NSLog(@"%@",error);
                    }];
                }
            }
            // 微信分享
            if([dataDic[@"methodName"] isEqualToString:@"wechatShare"]) {
                NSString *shareType = dataDic[@"shareType"];
                WXMediaMessage *message = [WXMediaMessage message];
                message.title = dataDic[@"title"];
                message.description = dataDic[@"desc"];
                NSURL *url = [NSURL URLWithString: dataDic[@"img"]];
                UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
                [message setThumbImage:image];
                
                WXWebpageObject *webpageObject = [WXWebpageObject object];
                webpageObject.webpageUrl = dataDic[@"webpageUrl"];
                message.mediaObject = webpageObject;
                
                SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
                req.bText = NO;
                req.message = message;
                if ([shareType isEqualToString:@"WXSceneTimeline"]) {
                    req.scene = WXSceneTimeline;
                }else{
                    req.scene = WXSceneSession;
                }
                [WXApi sendReq:req];
            }
            // 讯飞语音合成
            if([dataDic[@"methodName"] isEqualToString:@"iflySpeech"]){
                //启动合成会话
                [_iFlySpeechSynthesizer startSpeaking: dataDic[@"speechContent"]];
            }
            // 讯飞语音合成暂停播放
            if([dataDic[@"methodName"] isEqualToString:@"pauseSpeechSynthesizerVoice"]){
                //启动合成会话
                [_iFlySpeechSynthesizer pauseSpeaking];
            }
            // 讯飞语音合成恢复播放
            if([dataDic[@"methodName"] isEqualToString:@"resumeSpeechSynthesizerVoice"]){
                //启动合成会话
                [_iFlySpeechSynthesizer resumeSpeaking];
            }
            // 讯飞语音合成停止播放
            if([dataDic[@"methodName"] isEqualToString:@"stopSpeechSynthesizerVoice"]){
                //启动合成会话
                [_iFlySpeechSynthesizer stopSpeaking];
            }
            // 启动语音识别
            if([dataDic[@"methodName"] isEqualToString:@"startIflyRecognizer"]){
                [_iFlySpeechRecognizer startListening];
            }
            // 停止语音识别
            if([dataDic[@"methodName"] isEqualToString:@"stopIflyRecognizer"]){
                [_iFlySpeechRecognizer stopListening];
            }
            // 取消语音识别
            if([dataDic[@"methodName"] isEqualToString:@"cancelIflyRecognizer"]){
                [_iFlySpeechRecognizer cancel];
            }
            // 打开三方APP
            if([dataDic[@"methodName"] isEqualToString:@"openApp"]){
                [self openAppWithUrlScheme:[dataDic[@"urlScheme"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
            // 打开地图搜索
            if([dataDic[@"methodName"] isEqualToString:@"openMapSearch"]){
                NSString *latitude = dataDic[@"latitude"];
                NSString *longitude = dataDic[@"longitude"];
                [self openMapSearchWithLatitude:latitude.doubleValue Longtitude:longitude.doubleValue Keywords:dataDic[@"keywords"]];
            }
            // 打开地图导航
            if([dataDic[@"methodName"] isEqualToString:@"openMapNavi"]){
                NSString *latitude = dataDic[@"latitude"];
                NSString *longitude = dataDic[@"longitude"];
                [self openMapNaviWithLatitude:latitude.doubleValue Longtitude:longitude.doubleValue];
            }
            // 跳转VR全景视图
            if([dataDic[@"methodName"] isEqualToString:@"showVRPanorama"]){
                [self showVRPanoramaWithUrl:dataDic[@"panoramaUrl"]];
            }
        }
}

// 支付宝支付
- (void)aliPay:(NSString *)outTradeNo{
    NSString *urlStr = [NSString stringWithFormat:@"%@%@",_configDict[@"alipay"][@"URL"],outTradeNo];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:urlStr]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                // 待测试网络不好,或者网络加载失败时的回调
                                                NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                NSLog(@"%@", dataStr);
                                                // NOTE: 调用支付结果开始支付
                                                //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
                                                NSString *appScheme = @"PGWKWebView";
                                                [[AlipaySDK defaultService] payOrder:dataStr fromScheme:appScheme callback:^(NSDictionary *resultDic) {
                                                    NSLog(@"reslut = %@",resultDic);
                                                    [self aliPayCallJs:[resultDic objectForKey:@"resultStatus"]];
                                                }];
                                            }];
    [task resume];
}

// 支付宝支付回调
- (void)aliPayResultCode:(NSNotification *)noti
{
    NSString *resultStatus = [noti object];
    [self aliPayCallJs:resultStatus];
}

// 支付宝回调
- (void)aliPayCallJs:(NSString *)resultStatus
{
    NSString *method = [NSString stringWithFormat:@"_Native_aliPayResultCode(%@)",resultStatus];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

// 微信登录回调
- (void)wechatLoginResultInfo:(NSNotification *)noti
{
    NSString *responseJson = [noti object];
    NSString *method = [NSString stringWithFormat:@"_Native_wechatLoginResultInfo(%@)",responseJson];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//微信分享回调
- (void)wechatShareResultCode:(NSNotification *)noti
{
    NSString *errorcode = [noti object];
    NSString *method = [NSString stringWithFormat:@"_Native_wechatShareResultCode(%@)",errorcode];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

- (void)initNotification{
    // 添加微信登录通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wechatLoginResultInfo:) name:@"wechatLoginResultInfo" object:nil];
    // 添加支付宝支付通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aliPayResultCode:) name:@"aliPayResultCode" object:nil];
    // 添加微信分享通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wechatShareResultCode:) name:@"wechatShareResultCode" object:nil];
}

#pragma mark - 讯飞初始化及回调方法
- (void)initIflyCompound{
    //获取语音合成单例r
    _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    //设置协议委托对象
    _iFlySpeechSynthesizer.delegate = self;
    //设置合成参数
    //设置在线工作方式
    [_iFlySpeechSynthesizer setParameter:[IFlySpeechConstant TYPE_CLOUD]
                                  forKey:[IFlySpeechConstant ENGINE_TYPE]];
    //设置音量，取值范围 0~100
    [_iFlySpeechSynthesizer setParameter:@"50"
                                  forKey: [IFlySpeechConstant VOLUME]];
    //发音人，默认为”xiaoyan”，可以设置的参数列表可参考“合成发音人列表”
    [_iFlySpeechSynthesizer setParameter:@"xiaomei "
                                  forKey: [IFlySpeechConstant VOICE_NAME]];
    //保存合成文件名，如不再需要，设置为nil或者为空表示取消，默认目录位于library/cache下
    //    [_iFlySpeechSynthesizer setParameter:@"tts.pcm" forKey: [IFlySpeechConstant TTS_AUDIO_PATH]];
    [_iFlySpeechSynthesizer setParameter:nil forKey: [IFlySpeechConstant TTS_AUDIO_PATH]];
}

//IFlySpeechSynthesizerDelegate协议实现
//合成结束
- (void) onCompleted:(IFlySpeechError *) error {
    NSString *method = [NSString stringWithFormat:@"_Native_speechComplete('%@')",error.errorDesc];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//合成开始
- (void) onSpeakBegin {
    
}

//合成缓冲进度
- (void) onBufferProgress:(int) progress message:(NSString *)msg {
    
}

//合成播放进度
- (void) onSpeakProgress:(int) progress beginPos:(int)beginPos endPos:(int)endPos {
    
}

- (void)initIflyDiscern{
    //    //创建语音识别对象
    _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    //    //设置识别参数
    //    //设置为听写模式
    [_iFlySpeechRecognizer setParameter: @"iat" forKey: [IFlySpeechConstant IFLY_DOMAIN]];
    //asr_audio_path 是录音文件名，设置value为nil或者为空取消保存，默认保存目录在Library/cache下。
    //    [_iFlySpeechRecognizer setParameter:@"iat.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    [_iFlySpeechRecognizer setParameter:nil forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    // 设置语音前端点:静音超时时间，即用户多长时间不说话则当做超时处理1000~10000
    [_iFlySpeechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant VAD_BOS]];
    // 设置语音后端点:后端点静音检测时间，即用户停止说话多长时间内即认为不再输入， 自动停止录音0~10000
    [_iFlySpeechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant VAD_EOS]];
    _iFlySpeechRecognizer.delegate = self;
}

//IFlySpeechRecognizerDelegate协议实现
//识别结果返回代理
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [results objectAtIndex:0];
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    NSString *resu = [ISRDataHelper stringFromJson:result];
    _recognizerResult = [_recognizerResult stringByAppendingString:resu];
    if (isLast) {
        NSString *method = [NSString stringWithFormat:@"_Native_recognizerResult('%@')",_recognizerResult];
        [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
            // Block中处理是否通过了或者执行JS错误的代码
            NSLog(@"%@",error);
        }];
    }
}

//识别会话结束返回代理
- (void)onError: (IFlySpeechError *) error{
    NSString *method = [NSString stringWithFormat:@"_Native_recognizerError('%@')",error.errorDesc];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//停止录音回调
- (void) onEndOfSpeech{
    NSString *method = [NSString stringWithFormat:@"_Native_recognizerEnd()"];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//开始录音回调
- (void) onBeginOfSpeech{
    _recognizerResult = @"";
    NSString *method = [NSString stringWithFormat:@"_Native_recognizerBegin()"];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//音量回调函数
- (void) onVolumeChanged: (int)volume{
    NSString *method = [NSString stringWithFormat:@"_Native_recognizerVolume(%d)",volume];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

//会话取消回调
- (void) onCancel{
    NSString *method = [NSString stringWithFormat:@"_Native_recognizerCancel()"];
    [self evaluateJavaScript:method completionHandler:^(id item, NSError * _Nullable error) {
        // Block中处理是否通过了或者执行JS错误的代码
        NSLog(@"%@",error);
    }];
}

// 通过Scheme打开其他APP
- (void)openAppWithUrlScheme:(NSString *)urlSchemeStr{
    NSURL *urlScheme = [NSURL URLWithString:urlSchemeStr];
    if ([[UIDevice currentDevice].systemVersion integerValue] >= 10) {
        //iOS10以后,使用新API
        [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:^(BOOL success) { NSLog(@"scheme调用结束"); }]; }
    else {
        //iOS10以前,使用旧API
        [[UIApplication sharedApplication] openURL:urlScheme];
    }
}


// 跳转三方地图并搜索
- (void)openMapSearchWithLatitude:(double)latitude Longtitude:(double)longitude Keywords:(NSString *)keywords{
    // 创建
    UIAlertController *alertview=[UIAlertController alertControllerWithTitle:@"" message:@"请选择对应的地图查看景区周围服务设施" preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 设置按钮
    UIAlertAction *cancel=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *aMap = [UIAlertAction actionWithTitle:@"高德地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *aLocationSchemeStr = [[NSString stringWithFormat:@"iosamap://arroundpoi?sourceApplication=applicationName&keywords=%@&lat=%f&lon=%f&dev=0",keywords,latitude,longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [self openAppWithUrlScheme:aLocationSchemeStr];
    }];
    UIAlertAction *bMap = [UIAlertAction actionWithTitle:@"百度地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        CLLocationCoordinate2D baiduCoordinate = [self getBaiDuCoordinateByAMapCoordinate:coordinate];
        NSString *bLocationSchemeStr = [[NSString stringWithFormat:@"baidumap://map/place/search?query=%@&location=%f,%f&radius=1000&src=webapp.poi.yourCompanyName.yourAppName",keywords,baiduCoordinate.latitude,baiduCoordinate.longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [self openAppWithUrlScheme:bLocationSchemeStr];
    }];
    UIAlertAction *appleMap = [UIAlertAction actionWithTitle:@"苹果地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *appleMapSchemeStr = [[NSString stringWithFormat:@"http://maps.apple.com/?q=%@&sll=%f,%f&z=10&t=s",keywords,latitude, longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [self openAppWithUrlScheme:appleMapSchemeStr];
    }];
    
    [alertview addAction:cancel];
    BOOL canOpenAMap = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]];
    if(canOpenAMap){
        [alertview addAction:aMap];
    }
    BOOL canOpenBMap = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]];
    if (canOpenBMap) {
        [alertview addAction:bMap];
    }
    [alertview addAction:appleMap];
    
    [_controller presentViewController:alertview animated:YES completion:nil];
}

// 跳转三方地图并导航
- (void)openMapNaviWithLatitude:(double)latitude Longtitude:(double)longitude{
    // 创建
    UIAlertController *alertview=[UIAlertController alertControllerWithTitle:@"" message:@"请选择对应的地图查看景区周围服务设施" preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 设置按钮
    UIAlertAction *cancel=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *aMap = [UIAlertAction actionWithTitle:@"高德地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *aNaviSchemeStr = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",@"神骑出行",@"TrunkHelper",latitude, longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [self openAppWithUrlScheme:aNaviSchemeStr];
    }];
    UIAlertAction *bMap = [UIAlertAction actionWithTitle:@"百度地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        CLLocationCoordinate2D baiduCoordinate = [self getBaiDuCoordinateByAMapCoordinate:coordinate];
        NSString *bNaviSchemeStr = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=bd09ll",baiduCoordinate.latitude, baiduCoordinate.longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [self openAppWithUrlScheme:bNaviSchemeStr];
    }];
    UIAlertAction *appleMap = [UIAlertAction actionWithTitle:@"苹果地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(latitude, longitude);
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil]];
        [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                       MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
    }];
    
    [alertview addAction:cancel];
    BOOL canOpenAMap = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]];
    if(canOpenAMap){
        [alertview addAction:aMap];
    }
    BOOL canOpenBMap = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]];
    if (canOpenBMap) {
        [alertview addAction:bMap];
    }
    [alertview addAction:appleMap];
    
    [_controller presentViewController:alertview animated:YES completion:nil];
}

// 高德地图经纬度转换为百度地图经纬度
- (CLLocationCoordinate2D)getBaiDuCoordinateByAMapCoordinate:(CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(coordinate.latitude + 0.006, coordinate.longitude + 0.0065);
}

// 百度地图经纬度转换为高德地图经纬度
- (CLLocationCoordinate2D)getAMapCoordinateByBaiDuCoordinate:(CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(coordinate.latitude - 0.006, coordinate.longitude - 0.0065);
}

// 显示全景图
- (void)showVRPanoramaWithUrl:(NSString *)url{
    PanoramaViewController *panoramaVC = [[PanoramaViewController alloc] init];
    [_controller  presentViewController:panoramaVC  animated:YES completion:nil];
    NSString *str = [NSString stringWithFormat:@"%@",url];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showVRPanorama" object: str];
}

@end
