//
//  Library.h
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#ifndef cityu_lib_Library_h
#define cityu_lib_Library_h

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface Library : NSObject

@property NSString * host;

- (void) searchBooksWithString: (NSString *) string success: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (NSArray *) parseResultFromData: (NSData *) data;

@end



#endif
