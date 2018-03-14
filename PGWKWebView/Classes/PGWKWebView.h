//
//  PGWKWebView.h purepgmr的WKWebView Simple useful webview base on WKWebView
//  PGWKWebView
//
//  Created by 徐凯 on 02/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface PGWKWebView : WKWebView

/**
 * open WeChat login function
 * 开启微信登录功能
 */
-(void)openWeChatLoginWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open QQ login function
 * 开启QQ登录功能
 */
-(void)openQQLoginWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open Sina weibo login function
 * 开启新浪微博登录功能
 */
-(void)openSinaLoginWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open alipay function
 * 开启支付宝支付功能
 */
-(void)openALiPayLoginWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open WeChat pay function
 * 开启微信支付功能
 */
-(void)openWeChatPayWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open JPush push function
 * 开启极光推送功能
 */
-(void)openJPushWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open WeChat share function
 * 开启微信分享功能
 */
-(void)openWeChatShareWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open QQ share function
 * 开启QQ分享功能
 */
-(void)openQQShareWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open sina weibo share function
 * 开启新浪微博分享功能
 */
-(void)openSinaShareWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open umeng statistics function
 * 开启友盟统计功能
 */
-(void)openUMengStatWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open map function
 * 开启地图跳转功能
 */
-(void)openMapWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open VR Panorama function
 * 开启VR全景图功能
 */
-(void)openVRPanoramaWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open VR Video function
 * 开启VR全景视频功能
 */
-(void)openVRVideoWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open iFlyRecognizer login function
 * 开启讯飞语音识别功能
 */
-(void)openIFlyRecognizerWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/**
 * open iFlySynthesizer login function
 * 开启讯飞语音合成功能
 */
-(void)openIFlySynthesizerWithAppid:(NSString *)appid appsecret:(NSString *)appsecret;

/*! @abstract Returns a web view initialized with a specified frame and
 configuration.
 @param frame The frame for the new web view.
 @param configuration The configuration for the new web view.
 @result An initialized web view, or nil if the object could not be
 initialized.
 @discussion This is a designated initializer. You can use
 @link -initWithFrame: @/link to initialize an instance with the default
 configuration. The initializer copies the specified configuration, so
 mutating the configuration after invoking the initializer has no effect
 on the web view.
 */
- (id)initWithFrame:(CGRect)frame target:(nullable id)target;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@end
