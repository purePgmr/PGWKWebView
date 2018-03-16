//
//  WeChatTools.m 微信工具类
//  PGWebViewTest
//
//  Created by 徐凯 on 03/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import "WeChatTools.h"
// 导入网络框架
#import "AFNetworking.h"
// 导入PGWK配置
#import "PGWKConfig.h"
// 导入文件工具类
#import "FileTools.h"

@implementation WeChatTools

// 微信注册App
+ (void)wechatRegisterApp{
    NSDictionary *configDict = [FileTools readLocalFileWithName:@"PGConfig"];
    [WXApi registerApp:configDict[@"wechat"][@"AppID"]];
}

// 微信登录响应处理
+ (void)wechatLoginWithResp:(BaseResp *)resp{
    NSDictionary *configDict = [FileTools readLocalFileWithName:@"PGConfig"];
    // 向微信请求授权后,得到响应结果
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *temp = (SendAuthResp *)resp;
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
        NSString *accessUrlStr = [NSString stringWithFormat:@"%@/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", WX_BASE_URL, configDict[@"wechat"][@"AppID"], configDict[@"wechat"][@"AppSecret"], temp.code];
        [manager GET:accessUrlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *accessDict = [NSDictionary dictionaryWithDictionary:responseObject];
            NSString *accessToken = [accessDict objectForKey:WX_ACCESS_TOKEN];
            NSString *openID = [accessDict objectForKey:WX_OPEN_ID];
            NSString *refreshToken = [accessDict objectForKey:WX_REFRESH_TOKEN];
            // 本地持久化，以便access_token的使用、刷新或者持续
            if (accessToken && ![accessToken isEqualToString:@""] && openID && ![openID isEqualToString:@""]) {
                [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:WX_ACCESS_TOKEN];
                [[NSUserDefaults standardUserDefaults] setObject:openID forKey:WX_OPEN_ID];
                [[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:WX_REFRESH_TOKEN];
                [[NSUserDefaults standardUserDefaults] synchronize]; // 命令直接同步到文件里，来避免数据的丢失
            }
            [self wechatLoginByRequestForUserInfo];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        }];
    }
}

// 微信获取用户个人信息（UnionID机制）
+ (void)wechatLoginByRequestForUserInfo {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:WX_ACCESS_TOKEN];
    NSString *openID = [[NSUserDefaults standardUserDefaults] objectForKey:WX_OPEN_ID];
    NSString *userUrlStr = [NSString stringWithFormat:@"%@/userinfo?access_token=%@&openid=%@", WX_BASE_URL, accessToken, openID];
    // 请求用户数据
    [manager GET:userUrlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSDictionary dictionaryWithDictionary:responseObject];
        // 将字典序列化为json字符串
        NSData *data = [NSJSONSerialization dataWithJSONObject:userDict options:kNilOptions error:nil];
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        // 发送登录成功通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"wechatLoginResultInfo" object:json];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

// 微信分享响应处理
+ (void)wechatShareWithResp:(BaseResp *)resp{
    // 微信分享后得到响应结果
    if([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *temp = (SendMessageToWXResp *)resp;
        // 发送分享结果通知 0 分享成功 -2 取消分享
        NSString *str = [NSString stringWithFormat:@"%d",temp.errCode];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"wechatShareResultCode" object: str];
    }
}

@end
