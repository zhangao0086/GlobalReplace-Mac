//
//  FileMatchResult.h
//  GlobalReplace
//
//  Created by ZhangAo on 14-7-13.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileMatchResult : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSArray *matchs;

@end
