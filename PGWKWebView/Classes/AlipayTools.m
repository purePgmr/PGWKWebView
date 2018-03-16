//
//  AlipayTools.m 支付宝工具类
//  PGWebViewTest
//
//  Created by 徐凯 on 13/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import "AlipayTools.h"

@implementation AlipayTools

+ (void)handleOpenURL:(NSURL *) url{
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSString *resultStatus = [resultDic objectForKey:@"resultStatus"];
            // 发送支付结果通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"aliPayResultCode" object:resultStatus];
        }];
    }
}

@end

