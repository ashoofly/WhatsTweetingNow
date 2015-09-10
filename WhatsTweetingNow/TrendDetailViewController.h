//
//  SearchViewController.h
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/9/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Trend;

@interface TrendDetailViewController : TWTRTimelineViewController

@property (strong, nonatomic) Trend *trend;

@end
