//
//  ViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/4/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import "LoginViewController.h"
#import <TwitterKit/TwitterKit.h>
#import "SMXMLDocument.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TWTRLogInButton *logInButton = [TWTRLogInButton buttonWithLogInCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            NSLog(@"signed in as %@", [session userName]);
            [self performSegueWithIdentifier:@"LoggedIn" sender: self];
        } else {
            NSLog(@"error: %@", [error localizedDescription]);
        }
    }];
    logInButton.center = self.view.center;
    [self.view addSubview:logInButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
