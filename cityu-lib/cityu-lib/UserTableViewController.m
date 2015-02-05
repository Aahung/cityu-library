//
//  UserTableViewController.m
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "UserTableViewController.h"
#import <MBProgressHUD.h>
#import <SIAlertView.h>
#import "BookDetailViewController.h"

@interface UserTableViewController ()

@end

@implementation UserTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = true;
    
    self.navigationItem.title = @"My Library ";
    self.library = [[Library alloc] init];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"pull to refresh"];
    [self.refreshControl addTarget:self action:@selector(updateLibrary) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:self.refreshControl];
    [self.refreshControl endRefreshing];
    
    [self resetRefreshStackCount];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.refreshControl beginRefreshing];
    [self updateView];
    [self updateLibrary];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    if (![self.library getUser]) {
        return 0;
    }
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray * headers = @[@"My Fines", @"My Borrows", @"My Requests", @"My History"];
    return headers[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.userFines != nil) {
            return 1;
        }
    } else if (section == 1) {
        if (self.borrows != nil) {
            return [self.borrows count];
        }
    } else if (section == 2) {
        if (self.records != nil) {
            return [self.requests count];
        }
    } else if (section == 3) {
        if (self.records != nil) {
            return [self.records count];
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    NSInteger section = indexPath.section;
    
    if (section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"money" forIndexPath:indexPath];
        cell.textLabel.text = self.userFines;
    } else if (section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"borrow" forIndexPath:indexPath];
        cell.textLabel.text = [self.borrows[indexPath.item] valueForKey:@"title"];
        cell.detailTextLabel.text = [self.borrows[indexPath.item] valueForKey:@"status"];
    } else if (section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"request" forIndexPath:indexPath];
        cell.textLabel.text = [self.requests[indexPath.item] valueForKey:@"title"];
        cell.detailTextLabel.text = [self.requests[indexPath.item] valueForKey:@"status"];
    } else if (section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"record" forIndexPath:indexPath];
        NSMutableDictionary * book = self.records[indexPath.item];
        cell.textLabel.text = [book valueForKey:@"title"];
        cell.detailTextLabel.text = [book valueForKey:@"date"];
    }
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section > 0) {
        NSInteger section = indexPath.section;
        NSMutableDictionary * book;
        if (section == 1) {
            book = self.borrows[indexPath.item];
        } else if (section == 2) {
            book = self.requests[indexPath.item];
        } else if (section == 3) {
            book = self.records[indexPath.item];
        }
        [self performSegueWithIdentifier:@"detail" sender:book];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"detail"]) {
        UINavigationController * navigationController = (UINavigationController *)[segue destinationViewController];
        BookDetailViewController * bookDetailViewController;
        if ([navigationController isKindOfClass:[BookDetailViewController class]]) {
            bookDetailViewController = (BookDetailViewController *)navigationController;
        } else {
            bookDetailViewController = (BookDetailViewController *)[navigationController topViewController];
        }
        if (bookDetailViewController != nil) {
            bookDetailViewController.book = sender;
            return;
        }
    }
}

- (void) resetRefreshStackCount {
    self.refreshStackCount = 0;
}

- (void) incrementRefreshStackCount {
    self.refreshStackCount++;
}

- (void) decrementRefreshStachCount {
    self.refreshStackCount--;
    if (self.refreshStackCount == 0) {
        [self updateView];
        [self.refreshControl endRefreshing];
    }
}

- (void) updateView {
    if ([self.library getUser]) {
        self.loginfirstImage.hidden = true;
    } else {
        self.loginfirstImage.hidden = false;
    }
    [self.tableView reloadData];
}

- (void) updateLibrary {
    if ([self.library getUser]) {
        [self.library tryLogin:^(AFHTTPRequestOperation *operation, id responseObject){
            if ([self.library parseLogInSuccessFromData:responseObject]) {
                self.userFines = [self.library.userInfo valueForKey:@"fine"];
                
                // borrow
                [self incrementRefreshStackCount];
                [self.library downloadBorrowItems:^(AFHTTPRequestOperation *operation, id responseObject){
                    self.borrows = [self.library parseBorrowFromData:responseObject];
                    [self decrementRefreshStachCount];
                } error:^(AFHTTPRequestOperation *operation, id responseObject){
                    [self decrementRefreshStachCount];
                }];
                
                // record
                [self incrementRefreshStackCount];
                [self.library downloadRecordItems:^(AFHTTPRequestOperation *operation, id responseObject){
                    // reverse 
                    self.records = [[[self.library parseRecordFromData:responseObject] reverseObjectEnumerator] allObjects];
                    [self decrementRefreshStachCount];
                } error:^(AFHTTPRequestOperation *operation, id responseObject){
                    [self decrementRefreshStachCount];
                }];
                
                // request
                [self incrementRefreshStackCount];
                [self.library downloadRequestItems:^(AFHTTPRequestOperation *operation, id responseObject){
                    // reverse
                    self.requests = [self.library parseRequestFromData:responseObject];
                    [self decrementRefreshStachCount];
                } error:^(AFHTTPRequestOperation *operation, id responseObject){
                    [self decrementRefreshStachCount];
                }];
            } else {
                [self.refreshControl endRefreshing];
            }
        } error:^(AFHTTPRequestOperation *operation, id responseObject){
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Error" andMessage:@"Please check your network connection."];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDefault
                                  handler:nil];
            alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
            [alertView show];
            [self.refreshControl endRefreshing];
        }];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (IBAction)userAction:(id)sender {
    if ([self.library getUser]) {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Hi, %@", [self.library getUserName]] andMessage:@"You can touch the button to log out."];
        [alertView addButtonWithTitle:@"Cancel"
                                 type:SIAlertViewButtonTypeCancel
                              handler:nil];
        [alertView addButtonWithTitle:@"Log out"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:^(SIAlertView *alert) {
                                  // logout
                                  [self.library clearUser];
                                  [self updateView];
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        [alertView show];
    } else {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"ULibrary" andMessage:@"You will going to log in the CityU library system."];
        [alertView addButtonWithTitle:@"Cancel"
                                 type:SIAlertViewButtonTypeCancel
                              handler:nil];
        [alertView addButtonWithTitle:@"Log in"
                                 type:SIAlertViewButtonTypeDefault
                              handler:^(SIAlertView *alert) {
                                  [self performSegueWithIdentifier:@"login" sender:self];
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        [alertView show];
    }
}
@end
