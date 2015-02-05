//
//  LoginViewController.m
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "LoginViewController.h"
#import "MBProgressHUD.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)loginAction:(id)sender {
    NSString * name = self.nameTextField.text;
    NSString * sid = self.sidTextField.text;
    NSString * pin = self.pinTextField.text;
    
    if ([name  isEqual: @""] || [sid  isEqual: @""] || [pin  isEqual: @""]) {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Error" andMessage:@"All fields should be filled."];
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDefault
                              handler:nil];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        [alertView show];
        return;
    }
    
    Library * library = [[Library alloc] init];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [library tryLogin:name sid:sid pin:pin success:^(AFHTTPRequestOperation *operation, id responseObject){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString * error = [library parseLogInErrorFromData:responseObject];
        if (error != nil) {
            // alert
            error = [error stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            dispatch_async(dispatch_get_main_queue(), ^{
                SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Error" andMessage:error];
                [alertView addButtonWithTitle:@"OK"
                                         type:SIAlertViewButtonTypeDefault
                                      handler:nil];
                alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
                [alertView show];
            });
        } else {
            if ([library parseLogInSuccessFromData:responseObject]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [library setUser:name sid:sid pin:pin];
                    [self dismissViewControllerAnimated:true completion:nil];
                });
            }
        }
    } error: ^(AFHTTPRequestOperation *operation, NSError *error){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}


@end
