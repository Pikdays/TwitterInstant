//
//  RWSearchFormViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 02/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWSearchFormViewController.h"
#import "RWSearchResultsViewController.h"

@interface RWSearchFormViewController ()

@property(weak, nonatomic) IBOutlet UITextField *searchTextField;
@property(strong, nonatomic) RWSearchResultsViewController *resultsViewController;

@end

@implementation RWSearchFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Twitter Instant";

    self.resultsViewController = self.splitViewController.viewControllers[1];

}

#pragma mark - ⊂((・猿・))⊃ Set_Get

- (void)setSearchTextField:(UITextField *)searchTextField {
    _searchTextField  = searchTextField;

    CALayer *textFieldLayer = _searchTextField.layer;
    textFieldLayer.borderColor = [UIColor grayColor].CGColor;
    textFieldLayer.borderWidth = 2.0f;
    textFieldLayer.cornerRadius = 0.0f;
}

@end
