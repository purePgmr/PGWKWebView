//
//  IFlyTools.m
//  PGWebViewTest
//
//  Created by 徐凯 on 13/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import "IFlyTools.h"
#import "FileTools.h"

@implementation IFlyTools

+ (void)initIFly{
    NSDictionary *configDict = [FileTools readLocalFileWithName:@"PGConfig"];
    // 初始化讯飞语音
    //Appid是应用的身份信息，具有唯一性，初始化时必须要传入Appid。
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", configDict[@"ifly"][@"AppID"]];
    [IFlySpeechUtility createUtility:initString];
}

@end

