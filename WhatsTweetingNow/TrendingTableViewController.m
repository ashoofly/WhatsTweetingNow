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
                                             selector:@selector(fetchAllTweets)
                                                 name:@"GotTrends"
                                               object:nil];
    
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
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"GotWOEID" object:self];
            // [self fetchAllTrends];
             
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

- (void)fetchAllTweets {
    [self fetchTweets:self.localTrends];
    [self fetchTweets:self.countryTrends];
    [self fetchTweets:self.worldTrends];
    NSLog(@"Reloading table data...");
    [self reloadData];
}




- (void)fetchTrends:(NSString *)woeid forGeography:(Geography)geo {
    NSString *showTrendsEndpoint = @"https://api.twitter.com/1.1/trends/place.json";
    NSDictionary *params = @{@"id" : woeid}; //Austin
    NSError *clientError;
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:showTrendsEndpoint parameters:params error:&clientError];
    NSLog(@"fetching trends...");
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
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"GotTrends" object:self];
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

- (NSArray *)fetchTweets:(NSArray *)trends {
    
    NSString *showTweetsEndpoint = @"https://api.twitter.com/1.1/search/tweets.json";
    NSError *clientError;
    NSMutableArray *temp = [NSMutableArray array];
    
    for (Trend *t in trends) {
        NSString *query = t.name;
        NSDictionary *searchParams = [self getSearchParams:query forTrend:trends];
        
        NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:showTweetsEndpoint parameters:searchParams error:&clientError];
        
        NSLog(@"fetching tweets %@...", request.URL.absoluteString);
        if (request) {
            [[[Twitter sharedInstance] APIClient] sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (data) {
                    // handle the response data e.g.
                    NSError *jsonError;
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                    NSArray *tweetsJSON = [json valueForKey:@"statuses"];
                    //NSLog(@"Tweets found: %@", tweetsJSON);
                    if (tweetsJSON.count==0) {
                        NSLog(@"EMPTY RESULTS");
                        NSLog(@"%@ yielded no results. pulling from trends.", t.name);

                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            t.tweets = [TWTRTweet tweetsWithJSONArray:tweetsJSON];
                            [temp addObject:t];
                        });
                    }

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
    return temp.copy;
    
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

- (NSDictionary *)getSearchParams:(NSString *)query forTrend:(NSArray *)trends {
    if (trends == self.localTrends)
        return @{@"q" : query,
                 @"geocode" : [NSString stringWithFormat:@"%@,%@,50mi", self.localLatitude, self.localLongitude]};
    else if (trends == self.countryTrends)
        return @{@"q" : query,
                 @"geocode" : [NSString stringWithFormat:@"39.8282,98.5795,1500mi"]};
    else
        return @{@"q" : query};
    
    /* for country:
     take center of country, get radius.
     then check place, country_code to see if it's "US" or whatever. */
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


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
//        NSLog(@"opening native twitter app");
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://search?q=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];
//        
//    } else {
//        NSLog(@"No native twitter app");
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/search?q=Apple%20near%3AAustin%20within%3A100mi&src=typd"]];
//        
//    }
}



- (void)prepareSearchViewController:(TrendDetailViewController *)search withTerm:(NSString *)keyword
{
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        TrendDetailViewController *dest = [segue destinationViewController];
        if (indexPath.section==LOCAL)
            dest.trend = [self.localTrends objectAtIndex:indexPath.row];
        else if (indexPath.section==COUNTRY)
            dest.trend = [self.countryTrends objectAtIndex:indexPath.row];
        else if (indexPath.section==WORLD)
            dest.trend = [self.worldTrends objectAtIndex:indexPath.row];
    }
    
    
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
