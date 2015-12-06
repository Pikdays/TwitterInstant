//
//  RWSearchResultsViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 03/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "RWSearchResultsViewController.h"
#import "RWTableViewCell.h"
#import "RWTweet.h"

@interface RWSearchResultsViewController ()

@property(nonatomic, strong) NSArray *tweets;
@end

@implementation RWSearchResultsViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupData];
}


#pragma mark - ⊂((・猿・))⊃ SetupData

- (void)setupData {
    self.tweets = @[];
}

#pragma mark - ⊂((・猿・))⊃ Action

- (void)displayTweets:(NSArray *)tweets {
    self.tweets = tweets;
    [self.tableView reloadData];
}

#pragma mark - ⊂((・猿・))⊃ WebService

- (RACSignal *)signalForLoadingImage:(NSString *)imageUrl {
    RACScheduler *scheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground];

    // subscribeOn：来确保signal在指定的scheduler上执行
    return [[RACSignal createSignal:^RACDisposable *(id subscriber) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]]; // 权 图片请求不下来, error 256
        UIImage *image = [UIImage imageWithData:data];
        [subscriber sendNext:image];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:scheduler];
}

#pragma mark - ⊂((・猿・))⊃ Delegate
#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    RWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    RWTweet *tweet = self.tweets[indexPath.row];
    cell.twitterStatusText.text = tweet.status;
    cell.twitterUsernameText.text = [NSString stringWithFormat:@"@%@", tweet.username];

//    cell.twitterAvatarView.image = nil;
//
//    [[[self signalForLoadingImage:tweet.profileImageUrl]
//            deliverOn:[RACScheduler mainThreadScheduler]]
//            subscribeNext:^(UIImage *image) {
//                cell.twitterAvatarView.image = image;
//            }];

    [[[[self signalForLoadingImage:tweet.profileImageUrl]
            takeUntil:cell.rac_prepareForReuseSignal]
            deliverOn:[RACScheduler mainThreadScheduler]]
            subscribeNext:^(UIImage *image) {
                cell.twitterAvatarView.image = image;
            }];

    return cell;
}

@end
