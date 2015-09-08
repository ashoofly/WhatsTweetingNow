//
//  Trend.h
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/8/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Trend : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *promoted_content;
@property (strong, nonatomic) NSString *query;
@property (strong, nonatomic) NSString *url;

@end
