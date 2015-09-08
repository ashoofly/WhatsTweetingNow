//
//  Trend.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/8/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import "Trend.h"

@implementation Trend

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: name=%@; query=%@; url=%@", [self class], self.name, self.query, self.url];
}


@end
