//
//  AlipayTools.h 支付宝工具类
//  PGWebViewTest
//
//  Created by 徐凯 on 13/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//
#import <Foundation/Foundation.h>
// 导入支付宝SDK
#import "AlipaySDK/AlipaySDK.h"
@interface AlipayTools : NSObject

// 处理支付宝支付结果
+ (void)handleOpenURL:(NSURL *) url;

@end

