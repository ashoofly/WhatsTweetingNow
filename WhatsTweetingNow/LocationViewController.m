//
//  LocationViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/8/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import "LocationViewController.h"
#import "TrendingTableViewController.h"

@interface LocationViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TrendingTableViewController *dest = [segue destinationViewController];
    dest.localLocation = self.textField.text;
    
 
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
