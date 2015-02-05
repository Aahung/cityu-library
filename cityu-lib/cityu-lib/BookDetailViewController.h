//
//  BookDetailViewController.h
//  cityu-lib
//
//  Created by Xinhong LIU on 5/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface BookDetailViewController : UIViewController

@property NSMutableDictionary * book;
@property (weak, nonatomic) IBOutlet UIWebView *detailWebView;


@end
