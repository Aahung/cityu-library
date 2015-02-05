//
//  UserTableViewController.h
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Library.h"

@interface UserTableViewController : UITableViewController

- (IBAction)userAction:(id)sender;
@property Library * library;
@property (weak, nonatomic) IBOutlet UIImageView *loginfirstImage;

@property NSString * userFines;
@property NSArray * borrows;
@property NSArray * records;
@property NSArray * requests;
@property NSInteger refreshStackCount;

@end
