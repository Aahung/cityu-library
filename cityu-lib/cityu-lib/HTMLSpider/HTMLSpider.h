//
//  HTMLSpider.h
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTMLReader/HTMLReader.h>

@interface HTMLSpider : NSObject

@property NSString * html;
@property id spider;

- (void) setHTML: (NSString *) html;
- (NSString *) getHTML;
- (void) setSpiderWithUrl: (NSURL *) url;
- (NSArray *) getWeb;

@end
