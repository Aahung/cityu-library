//
//  LoginViewController.h
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Library.h"

@interface LoginViewController : UIViewController

- (IBAction)cancelAction:(id)sender;
- (IBAction)loginAction:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *sidTextField;
@property (weak, nonatomic) IBOutlet UITextField *pinTextField;


@end
