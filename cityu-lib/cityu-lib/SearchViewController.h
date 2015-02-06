//
//  ViewController.h
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Library.h"

@interface SearchViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate>


@property Library * library;

- (IBAction)aboutAction:(id)sender;

@end

