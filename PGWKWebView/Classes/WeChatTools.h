//
//  WeChatTools.h 微信工具类
//  PGWebViewTest
//
//  Created by 徐凯 on 03/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "WXApi.h"

@interface WeChatTools : NSObject

// 微信注册App
+ (void)wechatRegisterApp;

// 微信登录响应处理
+ (void)wechatLoginWithResp:(BaseResp *)resp;

// 微信分享响应处理
+ (void)wechatShareWithResp:(BaseResp *)resp;

@end
