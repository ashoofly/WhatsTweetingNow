//
//  LocationViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/8/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LocationViewController.h"
#import "TrendingTableViewController.h"

@interface LocationViewController () <UITextFieldDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) CLLocationDegrees latitude;
@property (assign, nonatomic) CLLocationDegrees longitude;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
         [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            [self monitorLocationChanges];
    }
    
    
    
  
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)monitorLocationChanges {
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.distanceFilter=1000;
    }
    [self.locationManager startUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self monitorLocationChanges];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.latitude = location.coordinate.latitude;
    self.longitude = location.coordinate.longitude;
    NSLog(@"Latitude: %f. Longitude: %f.", self.latitude, self.longitude);
    [self.locationManager stopUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"View disappearing. Location timestamp: %@", self.locationManager.location.timestamp);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"stopping monitoring right after view disappears...");
    [self.locationManager stopUpdatingLocation];
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
