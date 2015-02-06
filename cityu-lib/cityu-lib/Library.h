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

@property NSMutableDictionary * userInfo;

+ (NSString *) host;

- (void) searchBooksWithString: (NSString *) string methodIndex: (NSInteger) index success: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (void) tryLogin: (NSString *)name sid: (NSString *) sid pin: (NSString *) pin success: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (void) tryLogin: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (void) downloadBorrowItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (NSArray *) parseBorrowFromData: (NSData *) data;

- (void) downloadRecordItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (NSArray *) parseRecordFromData: (NSData *) data;

- (void) downloadRequestItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler;

- (NSArray *) parseRequestFromData: (NSData *) data;

- (NSArray *) parseResultFromData: (NSData *) data;

- (NSString *) parseLogInErrorFromData: (NSData *) data;

- (BOOL) parseLogInSuccessFromData: (NSData *) data;

- (BOOL) getUser;

- (NSString *) getUserName;

- (void) setUser: (NSString *)name sid: (NSString *) sid pin: (NSString *) pin;

- (void) clearUser;

- (NSArray *) getSearchMethods;
- (NSString *) getSearchMethodCodeByIndex: (NSInteger) index;

@end



#endif
