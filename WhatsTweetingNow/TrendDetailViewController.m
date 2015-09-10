//
//  SearchViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/9/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <TwitterKit/TwitterKit.h>
#import "TrendDetailViewController.h"
#import "Trend.h"


@interface TrendDetailViewController ()

@end

@implementation TrendDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Trend: %@", self.trend);
}



@end
