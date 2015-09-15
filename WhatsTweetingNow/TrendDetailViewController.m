//
//  SearchViewController.m
//  WhatsTweetingNow
//
//  Created by Angela Hsu on 9/9/15.
//  Copyright (c) 2015 Optaros. All rights reserved.
//

#import <TwitterKit/TwitterKit.h>
#import "TrendDetailViewController.h"
#import "Trend.h"


@interface TrendDetailViewController () <TWTRTweetViewDelegate>

@end

@implementation TrendDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.refreshControl = [[UIRefreshControl alloc] init];
//    [self.refreshControl addTarget:self
//                            action:@selector(fetchAllTrends)
//                  forControlEvents:UIControlEventValueChanged];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustRadius)
                                                 name:@"NoTweets"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayTimeline)
                                                 name:@"TweetsLoaded"
                                               object:nil];
    [self fetchTweets];
}

- (void)reloadData {
    NSLog(@"Trends fetched. Reloading data.");
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (NSDictionary *)getSearchParams {
    
    if (self.radius != -1) {
        return @{@"q" : self.query,
                 @"geocode" : [NSString stringWithFormat:@"%@,%dmi", self.centerLocation, self.radius],
                 @"count" : @"100"};
    } else {
        return @{@"q" : self.query,
                 @"count": @"100"};
    }
    
        /* for country:
         take center of country, get radius.
         then check place, country_code to see if it's "US" or whatever. */
    
}

- (void)adjustRadius {
    if (self.radius == 50)
        self.radius = 300;
    else if (self.radius == 300)
        self.radius = 1500;
    else if (self.radius == 1500)
        self.radius = -1;
    
    [self fetchTweets];
}

- (void) displayTimeline {
    if (self.radius != -1) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@ in %@ within %dmi", self.query, self.locationName, self.radius];
    } else {
        self.navigationItem.title = self.query;
    }
    
    [self reloadData];
    

}

- (void)fetchTweets {
    
    NSString *showTweetsEndpoint = @"https://api.twitter.com/1.1/search/tweets.json";
    NSError *clientError;
   
    
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:showTweetsEndpoint parameters:[self getSearchParams] error:&clientError];
    
    NSLog(@"fetching tweets %@...", request.URL.absoluteString);
    if (request) {
        [[[Twitter sharedInstance] APIClient] sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                // handle the response data e.g.
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                NSArray *tweetsJSON = [json valueForKey:@"statuses"];
                //NSLog(@"Tweets found: %@", tweetsJSON);
                if (!tweetsJSON || tweetsJSON.count==0) {
                    NSLog(@"EMPTY RESULTS");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NoTweets" object:self];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Tweets for radius %dmi:", self.radius);
                        self.tweets = [TWTRTweet tweetsWithJSONArray:tweetsJSON];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"TweetsLoaded" object:self];

                        NSLog(@"%@", self.tweets);
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

# pragma mark - UITableViewDelegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tweets count];
}

- (TWTRTweetTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWTRTweet *tweet = self.tweets[indexPath.row];
    
    TWTRTweetTableViewCell *cell = (TWTRTweetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TweetCell" forIndexPath:indexPath];
    [cell configureWithTweet:tweet];
    cell.tweetView.delegate = self;
    
    return cell;
}

// Calculate the height of each row
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWTRTweet *tweet = self.tweets[indexPath.row];
    
    return [TWTRTweetTableViewCell heightForTweet:tweet width:CGRectGetWidth(self.view.bounds)];
}


@end
