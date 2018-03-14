//
//  FileTools.m 文件工具类
//  PGWebViewTest
//
//  Created by 徐凯 on 03/03/2018.
//  Copyright © 2018 贵州中测. All rights reserved.
//

#import "FileTools.h"

@implementation FileTools

// 读取本地JSON文件
+ (NSDictionary *)readLocalFileWithName:(NSString *)name {
    // 获取文件路径
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    // 将文件数据化
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    // 对数据进行JSON格式化并返回字典形式
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}  

@end
