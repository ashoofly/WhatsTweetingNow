//
//  SearchViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/9/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <TwitterKit/TwitterKit.h>
#import "SearchViewController.h"


@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TWTRAPIClient *APIClient = [[Twitter sharedInstance] APIClient];
    TWTRSearchTimelineDataSource *searchTimelineDataSource = [[TWTRSearchTimelineDataSource alloc] initWithSearchQuery:self.searchTerm APIClient:APIClient];
    self.dataSource = searchTimelineDataSource;

}

@end
