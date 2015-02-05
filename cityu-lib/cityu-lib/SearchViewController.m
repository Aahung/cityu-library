//
//  ViewController.m
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "SearchViewController.h"
#import "BookTableViewCell.h"
#import "BookDetailViewController.h"
#import "Library.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MBProgressHUD.h"


@interface SearchViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property NSMutableArray * books;

@property BOOL lauched;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lauched = false;
    
    self.books = [[NSMutableArray alloc] init];
    
    // tapping background hide keyboard
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [singleTap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:singleTap];
    [self.navigationController.view addGestureRecognizer:singleTap];
    
    UIImageView * bgImageView = [[UIImageView alloc] init];
    [bgImageView setImage:[UIImage imageNamed:@"bg"]];
    self.tableView.backgroundView = bgImageView;
    self.tableView.backgroundView.alpha = 0.3;
    self.tableView.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    
    // version
    NSString * version = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleShortVersionString"];
    NSString * buildNumber = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleVersion"];
    self.searchBar.placeholder = [NSString stringWithFormat:@"version: %@ (%@)", version, buildNumber];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // deselect the tableviewcell
    NSIndexPath * selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath != nil) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:true];
    }
    
    // open the beyboard
    if (!self.lauched) {
        [self.searchBar becomeFirstResponder];
        self.lauched = true;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.books count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableDictionary * book = self.books[section];
    if ([book valueForKey:@"location"] != nil
        && [book valueForKey:@"call_number"] != nil) {
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString * cellIdentifier;
    if (indexPath.item == 0) {
        cellIdentifier = @"book";
    } else {
        cellIdentifier = @"location";
    }
    
    BookTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[BookTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSMutableDictionary * book = self.books[indexPath.section];
    
    if (indexPath.item == 0) {
        [cell titleLabel].text = [book valueForKey:@"title"];
        [cell authorLabel].text = [book valueForKey:@"author"];
        [cell publisherLabel].text = [book valueForKey:@"publisher"];
        cell.mediumLabel.text = [book valueForKey:@"medium"];
        
        if ([book valueForKey:@"thumbnail"] != nil) {
            NSURL * imageURL = [NSURL URLWithString:[book valueForKey:@"thumbnail"]];
            if (imageURL != nil) {
                [cell.thumbnail sd_setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"book"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL * imageURL) {
                    CGFloat height = image.size.height;
                    CGFloat width = image.size.width;
                    if (height < 40 || width < 40) {
                        // too small
                        [cell.thumbnail setImage:[UIImage imageNamed:@"book"]];
                    }
                }];
            }
        } else {
            [cell.thumbnail setImage:[UIImage imageNamed:@"book"]];
        }
        cell.thumbnail.hidden = false;
    } else {
        cell.locationLabel.text = [book valueForKey:@"location"];
        cell.callnLabel.text = [book valueForKey:@"call_number"];
        cell.statusLabel.text = [book valueForKey:@"status"];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return 120.0;
    } else {
        return 75.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 1) {
        // enter book detail when select the lcoation row
        NSIndexPath * bookRowIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
        [self.tableView selectRowAtIndexPath:bookRowIndexPath animated:true scrollPosition:UITableViewScrollPositionNone];
        [self.tableView deselectRowAtIndexPath:indexPath animated:true];
        [self performSegueWithIdentifier:@"detail" sender:self];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    [self.searchBar resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        Library * library = [[Library alloc] init];
        
        [library searchBooksWithString:searchBar.text success: ^(AFHTTPRequestOperation *operation, id responseObject){
            NSArray * books = [library parseResultFromData:responseObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.books = [NSMutableArray arrayWithArray:books];
                [self.tableView reloadData];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        } error: ^(AFHTTPRequestOperation *operation, NSError *error){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSLog(@"Error: %@", error);
        }];
    });
    
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
            NSIndexPath * selectedIndexPath = [self.tableView indexPathForSelectedRow];
            bookDetailViewController.book = [self.books objectAtIndex:selectedIndexPath.section];
            return;
        }
    }
}

- (void)resignOnTap:(id)iSender {
    [self.searchBar resignFirstResponder];
}

@end
