//
//  RWSearchFormViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 02/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWSearchFormViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h> ﻿​
#import "RWSearchResultsViewController.h"
#import "RWTweet.h"
#import "NSArray+LinqExtensions.h"

typedef NS_ENUM(NSInteger, RWTwitterInstantError) {
    RWTwitterInstantErrorAccessDenied,
    RWTwitterInstantErrorNoTwitterAccounts,
    RWTwitterInstantErrorInvalidResponse
};

static NSString *const RWTwitterInstantDomain = @"TwitterInstant";

@interface RWSearchFormViewController ()

@property(weak, nonatomic) IBOutlet UITextField *searchTextField;
@property(strong, nonatomic) RWSearchResultsViewController *resultsViewController;

@property(strong, nonatomic) ACAccountStore *accountStore;
@property(strong, nonatomic) ACAccountType *twitterAccountType;

@end

@implementation RWSearchFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Twitter Instant";

    [self setupData];
    [self setupRAC];
}

#pragma mark - ⊂((・猿・))⊃ SetupData

- (void)setupData {
    self.resultsViewController = self.splitViewController.viewControllers[1];

    // 创建了一个account store和Twitter账户标识符
    self.accountStore = [[ACAccountStore alloc] init];
    self.twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
}

#pragma mark - ⊂((・猿・))⊃ SetupRAC

- (void)setupRAC {
    @weakify(self)
    [[self.searchTextField.rac_textSignal
            map:^id(NSString *text) {
                @strongify(self)
                return [self isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
            }] subscribeNext:^(UIColor *color) {
        @strongify(self)
        self.searchTextField.backgroundColor = color;
    }];

    // then, then方法会等待completed事件的发送
    // throttle, 当停止输入超过500毫秒后，才会开始搜索
    // deliverOn, 交付给主线程
    [[[[[[[self requestAccessToTwitterSignal]
            then:^RACSignal * {
                @strongify(self)
                return self.searchTextField.rac_textSignal;
            }]
            filter:^BOOL(NSString *text) {
                @strongify(self)
                return [self isValidSearchText:text];
            }]
            throttle:0.5]
            flattenMap:^RACStream *(NSString *text) {
                @strongify(self)
                return [self signalForSearchWithText:text];
            }]
            deliverOn:[RACScheduler mainThreadScheduler]]
            subscribeNext:^(NSDictionary *jsonSearchResult) {
                NSArray *statuses = jsonSearchResult[@"statuses"];
                NSArray *tweets = [statuses linq_select:^id(id tweet) {
                    return [RWTweet tweetWithStatus:tweet];
                }];
                [self.resultsViewController displayTweets:tweets];
                NSLog(@"%@", jsonSearchResult);
            } error:^(NSError *error) {
        NSLog(@"An error occurred: %@", error);
    }];
}

#pragma mark - ⊂((・猿・))⊃ Set_Get

- (void)setSearchTextField:(UITextField *)searchTextField {
    _searchTextField = searchTextField;

    CALayer *textFieldLayer = _searchTextField.layer;
    textFieldLayer.borderColor = [UIColor grayColor].CGColor;
    textFieldLayer.borderWidth = 2.0f;
    textFieldLayer.cornerRadius = 0.0f;
}

#pragma mark - ⊂((・猿・))⊃ Action

- (BOOL)isValidSearchText:(NSString *)text {
    return text.length > 2;
}

- (RACSignal *)requestAccessToTwitterSignal {
    NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorAccessDenied userInfo:nil];

    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self)
        [self.accountStore requestAccessToAccountsWithType:self.twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
            if (!granted) {
                [subscriber sendError:accessError];
            } else {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }];
}

#pragma mark - ⊂((・猿・))⊃ WebService

- (RACSignal *)signalForSearchWithText:(NSString *)text {
    NSError *noAccountsError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorNoTwitterAccounts userInfo:nil];
    NSError *invalidResponseError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorInvalidResponse userInfo:nil];

    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        SLRequest *request = [self requestforTwitterSearchWithText:text];

        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterAccountType];
        if (twitterAccounts.count == 0) {
            [subscriber sendError:noAccountsError];
        } else {
            [request setAccount:[twitterAccounts lastObject]];

            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (urlResponse.statusCode == 200) {
                    NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                    [subscriber sendNext:timelineData];
                    [subscriber sendCompleted];
                } else {
                    [subscriber sendError:invalidResponseError];
                }
            }];
        }
        return nil;
    }];
}

- (SLRequest *)requestforTwitterSearchWithText:(NSString *)text {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSDictionary *params = @{@"q" : text};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
    return request;
}


@end
