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
#import "SearchViewController.h"

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
    [self getWOEID];


}

- (void)reloadData {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}


- (void)getWOEID {
    self.localLocation = @"Austin";
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
             SMXMLElement *place = [[places childrenNamed:@"place"] firstObject];
             SMXMLElement *country = [[place childrenNamed:@"country"] firstObject];
             SMXMLElement *centroid = [place childNamed:@"centroid"];
             self.localWOEID = [place valueWithPath:@"woeid"];
             self.countryWOEID =[country attributeNamed:@"woeid"];
             self.countryLocation = [place valueWithPath:@"country"];
             self.localLatitude = [centroid valueWithPath:@"latitude"];
             self.localLongitude = [centroid valueWithPath:@"longitude"];
             
             [self fetchAllTrends];
             
         } else {
             NSLog(@"%@", connectionError);
         }
     }];
    
}
- (void)fetchAllTrends {
    [self fetchTrends:self.localWOEID forGeography:LOCAL];
    [self fetchTrends:self.countryWOEID forGeography:COUNTRY];
    [self fetchTrends:GLOBAL_WOEID forGeography:WORLD];
}


- (void)fetchTrends:(NSString *)woeid forGeography:(Geography)geo {
    NSLog(@"self.localWOEID = %@", self.localWOEID);
    NSString *showTrendsEndpoint = @"https://api.twitter.com/1.1/trends/place.json";
    NSDictionary *params = @{@"id" : woeid}; //Austin
    NSError *clientError;
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:showTrendsEndpoint parameters:params error:&clientError];
    NSLog(@"fetching...");
    if (request) {
        [[[Twitter sharedInstance] APIClient] sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                // handle the response data e.g.
                NSError *jsonError;
                NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"%@", [self parseJSONObject:json.firstObject]);
                    switch (geo) {
                        case LOCAL:
                            self.localTrends = [self parseJSONObject:json.firstObject];
                            break;
                        case COUNTRY:
                            self.countryTrends = [self parseJSONObject:json.firstObject];
                            break;
                        case WORLD:
                            self.worldTrends = [self parseJSONObject:json.firstObject];
                            break;
                    }
                    if (self.localTrends && self.countryTrends && self.worldTrends) {
                        self.allTrends = @[self.localTrends, self.countryTrends, self.worldTrends];
                        for (NSArray *trends in self.allTrends) {
                            for (Trend *t in trends) {
                                NSLog(@"%@", t.name);
                            }
                            NSLog(@"\n");
                        }
                        [self reloadData];
                    }

                });
            }
            else {
                NSLog(@"Error: %@", connectionError);
                [self.refreshControl endRefreshing];

            }
        }];
    }
    else {
        NSLog(@"Error: %@", clientError);
    }
}

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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.allTrends count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) {
        return @"Austin";
    }
    else if (section==1) {
        return @"U.S.";
    }
    else if (section==2) {
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
    NSLog(@"%@", cell.textLabel.text);
    return cell;
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        NSLog(@"opening native twitter app");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://search?q=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];
        
    } else {
        NSLog(@"No native twitter app");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/search?q=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];
        
    }
}

- (void)prepareSearchViewController:(SearchViewController *)search withTerm:(NSString *)keyword
{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        NSLog(@"opening native twitter app");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://search?query=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];

    } else {
        NSLog(@"No native twitter app");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/search?q=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];

    }

//    if ([sender isKindOfClass:[UITableViewCell class]]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
//        SearchViewController *dest = [segue destinationViewController];
//        NSString *query = ((UITableViewCell *)sender).textLabel.text;
//        if (indexPath.section==0)
//            dest.searchTerm = [NSString stringWithFormat:@"%@ near:%@ within:100mi", query, self.localLocation];
//        else if (indexPath.section==1)
//            dest.searchTerm = [NSString stringWithFormat:@"%@ near:%@", query, self.countryLocation];
//        else
//            dest.searchTerm = query;
//    }
    
    
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
