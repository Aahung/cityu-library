//
//  ViewController.m
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "SearchViewController.h"
#import "BookTableViewCell.h"
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // deselect the tableviewcell
    NSIndexPath * selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath != nil) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:true];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.lauched) {
        [self.searchBar becomeFirstResponder];
        self.lauched = true;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.books count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BookTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"book"];
    
    if (cell == nil) {
        cell = [[BookTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"book"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSMutableDictionary * book = self.books[indexPath.section];
    [cell titleLabel].text = [book valueForKey:@"title"];
    [cell authorLabel].text = [book valueForKey:@"author"];
    [cell publisherLabel].text = [book valueForKey:@"publisher"];
    
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
    }
    
    return cell;
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


- (void)resignOnTap:(id)iSender {
    [self.searchBar resignFirstResponder];
}

@end
