//
//  Book.h
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Book : NSObject

@property NSString * bookId;
@property NSString * title;
@property NSURL * link;
@property NSString * author;
@property NSString * publisher;
@property NSURL * thumbnail;
@property NSString * medium;

@property NSString * location;
@property NSString * call;
@property NSString * status;

@end
