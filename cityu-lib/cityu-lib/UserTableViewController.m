//
//  UserTableViewController.m
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "UserTableViewController.h"
#import <MBProgressHUD.h>
#import "BookDetailViewController.h"
#import "Classes/SimpleAlertViewController.h"

@interface UserTableViewController ()

@end

@implementation UserTableViewController

+ (NSArray *) headers {
    return @[@"My Fines", @"My Borrows", @"My Requests", @"My History"];
}

- (NSArray *) headerLinks {
    NSArray * keys = @[@"fine_link", @"borrow_link", @"request_link", @"record_link"];
    NSMutableArray * links = [[NSMutableArray alloc] init];
    for (NSString * key in keys) {
        NSString * link = [self.library.userInfo valueForKey:key];
        if (link == nil) {
            link = @"";
        }
        [links addObject:link];
    }
    return links;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = true;
    
    self.navigationItem.title = @"My Library ";
    self.library = [[Library alloc] init];
    
    
    // background
    UIImageView * bgImageView = [[UIImageView alloc] init];
    [bgImageView setImage:[UIImage imageNamed:@"bg"]];
    self.tableView.backgroundView = bgImageView;
    self.tableView.backgroundView.alpha = 0.3;
    self.tableView.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 55;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView * view =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 55)];
    UIButton * button=[UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 320, 55)];
    [button setTitle:[UserTableViewController headers][section] forState:UIControlStateNormal];
    [button setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [view addSubview:button];
    [button addTarget:self action:@selector(openSection:) forControlEvents:UIControlEventTouchUpInside];
    return view;
    
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
    if ([segue.identifier isEqual: @"detail"]) {
        BookDetailViewController * bookDetailViewController = (BookDetailViewController *)[segue destinationViewController];
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
            [[[SimpleAlertViewController alloc] initWithViewController:self] showAlertWithTitle:@"Error" message:@"Please check your network connection."];
            [self.refreshControl endRefreshing];
        }];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (IBAction)userAction:(id)sender {
    if ([self.library getUser]) {
        [[[SimpleAlertViewController alloc] initWithViewController:self] showAlertWithTitle:[NSString stringWithFormat:@"Hi, %@", [self.library getUserName]] message:@"You can touch the button to log out." defaultTitle:@"Log out" defaultHandler:^{
            // logout
            [self.library clearUser];
            [self updateView];
        }];
    } else {
        [[[SimpleAlertViewController alloc] initWithViewController:self] showAlertWithTitle:@"ULibrary" message:@"You will going to log in the CityU library system." defaultTitle:@"Log in" defaultHandler:^{
            [self performSegueWithIdentifier:@"login" sender:self];
        }];
    }
}

- (void) openSection: (UIButton *) sender {
    if (self.library.userInfo == nil) {
        // wait
        return;
    }
    NSString * headerText = sender.titleLabel.text;
    NSInteger index = [[UserTableViewController headers] indexOfObject:headerText];
    NSArray * links = [self headerLinks];
    NSString * link = links[index];
    if ([link isEqual: @""]) {
        [[[SimpleAlertViewController alloc] initWithViewController:self] showAlertWithTitle:@"Sorry" message:[NSString stringWithFormat:@"%@ is not reachable now.", headerText]];
        return;
    }
    NSDictionary * data = @{@"title": headerText, @"link": link};
    [self performSegueWithIdentifier:@"detail" sender:data];
}

@end
