//
//  SearchViewController.h
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/9/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Trend;

@interface TrendDetailViewController : UITableViewController   

@property (strong, nonatomic) NSString *query;
@property (strong, nonatomic) NSString *centerLocation;
@property (strong, nonatomic) NSString *locationName;
@property (nonatomic) int radius;
@property (strong, nonatomic) NSArray *tweets;

@end
