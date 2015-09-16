//
//  TrendingTableViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/4/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import "TrendingTableViewController.h"
#import <TwitterKit/TwitterKit.h>
#import "SMXMLDocument.h"
#import "Trend.h"
#import "APIKeys.h"
#import "TrendDetailViewController.h"

typedef NS_ENUM(NSInteger, Geography) {
    LOCAL,
    COUNTRY,
    WORLD
};

#define GLOBAL_WOEID @"1"

@interface TrendingTableViewController ()

@property (strong, nonatomic) NSArray *localTrends;
@property (strong, nonatomic) NSArray *countryTrends;
@property (strong, nonatomic) NSArray *worldTrends;
@property (strong, nonatomic) NSArray *allTrends;
@property (strong, nonatomic) NSString *localWOEID;
@property (strong, nonatomic) NSString *countryWOEID;


@end

@implementation TrendingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(fetchAllTrends)
                  forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchAllTrends)
                                                 name:@"GotWOEID"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:@"GotTrends"
                                               object:nil];
    
    if (self.localLatitude && self.localLongitude)
        [self getWOEIDFromCoordinates];
    else if (self.localLocation)
        [self getWOEIDsFromName:self.localLocation];
    
}

- (void)reloadData {
    NSLog(@"Trends fetched. Reloading data.");
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

# pragma mark - API Calls

- (void)getWOEIDFromCoordinates {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://query.yahooapis.com/v1/public/yql?q=select%%20*%%20from%%20geo.placefinder%%20where%%20text%%3D%%22%@%%2C%@%%22%%20and%%20gflags%%3D%%22R%%22&diagnostics=true&format=xml", self.localLatitude, self.localLongitude]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSError *error;
             SMXMLDocument *things = [SMXMLDocument documentWithData:data error:&error];
             SMXMLElement *resultList = [things childNamed:@"results"];
             NSArray *results = [resultList childrenNamed:@"Result"];
             SMXMLElement *chosenResult = [results firstObject];
             self.localLocation = [chosenResult valueWithPath:@"city"];
             [self getWOEIDsFromName:self.localLocation];
         } else {
             NSLog(@"%@", connectionError);
         }
     }];

}

- (void)getWOEIDsFromName:(NSString *)string {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://where.yahooapis.com/v1/places.q('%@')?appid=%@", self.localLocation, YahooAPIKey]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSError *error;
             
             SMXMLDocument *places = [SMXMLDocument documentWithData:data error:&error];
             if (error) {
                 [self raiseAlert:[NSString stringWithFormat:@"'%@' not found", self.localLocation] mesage:@"Please try another location."];
                 return;
             }
             SMXMLElement *place = [[places childrenNamed:@"place"] firstObject];
             SMXMLElement *country = [[place childrenNamed:@"country"] firstObject];
             SMXMLElement *centroid = [place childNamed:@"centroid"];
             self.localWOEID = [place valueWithPath:@"woeid"];
             self.countryWOEID =[country attributeNamed:@"woeid"];
             self.countryLocation = [country attributeNamed:@"code"];
             if (!self.localLatitude && !self.localLongitude) {
                 self.localLatitude = [centroid valueWithPath:@"latitude"];
                 self.localLongitude = [centroid valueWithPath:@"longitude"];
             }
             if (!place || !country || !centroid) {
                 [self raiseAlert:[NSString stringWithFormat:@"'%@' not found", self.localLocation] mesage:@"Please try another location."];
                 return;
             }
             [[NSNotificationCenter defaultCenter] postNotificationName:@"GotWOEID" object:self];
             
         } else {
             NSLog(@"%@", connectionError);
                 [self raiseAlert:@"Problem with connection" mesage:@"Please try again."];
         }
     }];
    
}
- (void)fetchAllTrends {
    NSLog(@"Received notification. Fetching all trends...");
    [self fetchTrends:self.localWOEID forGeography:LOCAL];
    [self fetchTrends:self.countryWOEID forGeography:COUNTRY];
    [self fetchTrends:GLOBAL_WOEID forGeography:WORLD];
    
}

- (void)fetchTrends:(NSString *)woeid forGeography:(Geography)geo {
    NSString *showTrendsEndpoint = @"https://api.twitter.com/1.1/trends/place.json";
    NSDictionary *params = @{@"id" : woeid};
    NSError *clientError;
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:showTrendsEndpoint parameters:params error:&clientError];
    NSLog(@"fetching trends... %@", request.URL.absoluteString);
    if (request) {
        [[[Twitter sharedInstance] APIClient] sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                // handle the response data e.g.
                NSError *jsonError;
                NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (geo) {
                        case LOCAL:
                            self.localTrends = [self parseJSONObject:json.firstObject];
                            NSLog(@"self.localTrends = %@", self.localTrends);
                            break;
                        case COUNTRY:
                            self.countryTrends = [self parseJSONObject:json.firstObject];
                            NSLog(@"self.countryTrends = %@", self.localTrends);
                            break;
                        case WORLD:
                            self.worldTrends = [self parseJSONObject:json.firstObject];
                            NSLog(@"self.worldTrends = %@", self.localTrends);

                            break;
                    }
                    if (self.localTrends && self.countryTrends && self.worldTrends) {
                        self.allTrends = @[self.localTrends, self.countryTrends, self.worldTrends];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"GotTrends" object:self];
                    }

                });
            }
            else {
                NSLog(@"Error: %@", connectionError);
                [self.refreshControl endRefreshing];
                [self raiseAlert:[NSString stringWithFormat:@"No trends found for '%@'", self.localLocation] mesage:@"Please try another location."];

            }
        }];
    }
    else {
        NSLog(@"Error: %@", clientError);
        [self raiseAlert:@"Problem connecting with Twitter" mesage:@"Please try again."];
    }
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.allTrends count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==LOCAL) {
        return self.localLocation;
    }
    else if (section==COUNTRY) {
        return self.countryLocation;
    }
    else if (section==WORLD) {
        return @"World";
    }
    return @"Nothing";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[self.allTrends objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Trend Cell" forIndexPath:indexPath];
    cell.textLabel.text = ((Trend *)[[self.allTrends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name;
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        TrendDetailViewController *dest = [segue destinationViewController];
        dest.query = ((UITableViewCell *)sender).textLabel.text;
        
        if (indexPath.section==LOCAL) {
            dest.centerLocation = [NSString stringWithFormat:@"%@,%@", self.localLatitude, self.localLongitude];
            dest.locationName = self.localLocation;
            dest.radius = 50;
        }
        else if (indexPath.section==COUNTRY) {
            dest.centerLocation = [NSString stringWithFormat:@"39.8282,98.5795"];
            dest.locationName = self.countryLocation;
            dest.radius = 1500;
        }
        else if (indexPath.section==WORLD) {
            dest.centerLocation = @"GLOBAL";
            dest.locationName = @"GLOBAL";
            dest.radius = -1;
        }
    }
}

# pragma mark - Utility methods

- (NSArray *) parseJSONObject:(NSDictionary *)json {
    NSArray *jsonTrends = [json objectForKey:@"trends"];
    
    NSMutableArray *tempTrends = [[NSMutableArray alloc] init];
    for (NSDictionary *t in jsonTrends) {
        Trend *trend = [[Trend alloc] init];
        
        for (NSString *key in t) {
            if ([trend respondsToSelector:NSSelectorFromString(key)]) {
                [trend setValue:[t valueForKey:key] forKey:key];
            }
        }
        
        [tempTrends addObject:trend];
    }
    return tempTrends.copy;
}

- (void)raiseAlert:(NSString *)title mesage:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
