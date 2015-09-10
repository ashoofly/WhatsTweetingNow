//
//  TrendingTableViewController.h
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/4/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrendingTableViewController : UITableViewController

@property (strong, nonatomic) NSString *localLocation;
@property (strong, nonatomic) NSString *countryLocation;
@property (strong, nonatomic) NSString *localLatitude;
@property (strong, nonatomic) NSString *localLongitude;
@property (strong, nonatomic) NSArray *localTweets;
@property (strong, nonatomic) NSArray *countryTweets;
@property (strong, nonatomic) NSArray *globalTweets;

@end
