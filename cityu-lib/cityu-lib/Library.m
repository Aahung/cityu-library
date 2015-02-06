//
//  Library.m
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "Library.h"
#import <AFNetworking.h>
#import <HTMLReader/HTMLReader.h>
#import "HTMLSpider.h"
#include "iconv.h"

@implementation Library

+ (NSString *) host {
    return @"http://lib.cityu.edu.hk";
}

- (NSString *) buildQueryString: (NSArray *) keys values: (NSArray *) values {
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSUInteger n = [keys count];
    for (int i = 0; i < n; ++i) {
        NSString * key = [keys[i] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * value = [values[i] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * pair = [NSString stringWithFormat:@"%@=%@", key, value];
        [array addObject: pair];
    }
    return [array componentsJoinedByString:@"&"];
}


- (void) searchBooksWithString:(NSString *)string  methodIndex: (NSInteger) index success: successHandler error: errorHandler {
    NSArray * keys = [NSArray arrayWithObjects:@"searchtype", @"searcharg", @"searchscope", @"SORT", @"extended", @"SUBMIT", nil];
    NSArray * values = [NSArray arrayWithObjects:[self getSearchMethodCodeByIndex:index], string, @"8", @"D", @"0", @"Search", nil];
    NSString * queryString = [self buildQueryString:keys values:values];
    NSString * URLString = [NSString stringWithFormat:@"http://lib.cityu.edu.hk/search~S8/?%@", queryString];
    [self downloadByURLString:URLString success:successHandler error:errorHandler];
}

- (NSArray *) parseResultFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"book.spider" withExtension:@"json"]];
    NSArray * books = [spider getWeb];
    for (NSMutableDictionary * book in books) {
        [book setObject:@"" forKey:@"author"];
        [book setObject:@"" forKey:@"publisher"];
        
        // medium
        NSString * medium = [book valueForKey:@"medium"];
        if (medium != nil) {
            medium = [medium stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            medium = [medium stringByReplacingOccurrencesOfString:@"Request" withString:@""];
            [book setObject:medium forKey:@"medium"];
        }
        
        // author and publisher
        NSString * author_publisher = [[book valueForKey:@"title_author_publisher"] stringByReplacingOccurrencesOfString:[book valueForKey:@"title"] withString:@""];
        NSMutableArray * tokens = [NSMutableArray arrayWithArray:[author_publisher componentsSeparatedByString:@"\n"]];
        [tokens removeObject:@""];
        if ([tokens count] >= 2) {
            // found author and publisher
            [book setObject:tokens[0] forKey:@"author"];
            [book setObject:tokens[1] forKey:@"publisher"];
        }
        [book removeObjectForKey:@"title_author_publisher"];
        
        // trim
        NSArray * keys = [book allKeys];
        for (NSString * key in keys) {
            [book setObject:[[book valueForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:key];
        }
    }
    return books;
}

- (BOOL) getUser {
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"name"] == nil || [[NSUserDefaults standardUserDefaults] objectForKey:@"sid"] == nil || [[NSUserDefaults standardUserDefaults] objectForKey:@"pin"] == nil) {
        return false;
    }
    return true;
}

- (NSString *) getUserName {
    [[NSUserDefaults standardUserDefaults] synchronize];
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"name"];
}

- (void) setUser: (NSString *)name sid: (NSString *) sid pin: (NSString *) pin {
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"name"];
    [[NSUserDefaults standardUserDefaults] setObject:sid forKey:@"sid"];
    [[NSUserDefaults standardUserDefaults] setObject:pin forKey:@"pin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) clearUser {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"name"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) tryLogin: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self tryLogin:[[NSUserDefaults standardUserDefaults] objectForKey:@"name"] sid:[[NSUserDefaults standardUserDefaults] objectForKey:@"sid"] pin:[[NSUserDefaults standardUserDefaults] objectForKey:@"pin"] success:successHandler error:errorHandler];
}

- (void) tryLogin: (NSString *)name sid: (NSString *) sid pin: (NSString *) pin success: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    NSDictionary *parameters = @{@"name": name, @"code": sid, @"pin": pin, @"pat_submit": @"xxx"};
    [manager POST:@"https://lib.cityu.edu.hk/patroninfo" parameters:parameters success: successHandler failure: errorHandler];
}

- (NSString *) parseLogInErrorFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"faillogin.spider" withExtension:@"json"]];
    NSArray * error = [spider getWeb];
    if ([error count] == 0) {
        return nil;
    }
    if ([error[0] valueForKey:@"error"] != nil) {
        return [error[0] valueForKey:@"error"];
    }
    return nil;
}

- (BOOL) parseLogInSuccessFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"user.spider" withExtension:@"json"]];
    NSArray * header = [spider getWeb];
    if ([header count] > 0) {
        if ([header[0] valueForKey:@"header"] != nil) {
            if ([[header[0] valueForKey:@"header"] isEqual:@"My Circulation Record"]) {
                self.userInfo = header[0];
                return true;
            }
        }
    }
    return false; // unknown error
}

- (void) downloadBorrowItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler {
    [self downloadByURLString:[NSString stringWithFormat:@"%@%@", Library.host, [self.userInfo valueForKey:@"borrow_link"]] success:successHandler error:errorHandler];
}

- (NSArray *) parseBorrowFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"borrow.spider" withExtension:@"json"]];
    NSArray * books = [spider getWeb];
    return books;
}

- (void) downloadRecordItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler {
    [self downloadByURLString:[NSString stringWithFormat:@"%@%@", Library.host, [self.userInfo valueForKey:@"record_link"]] success:successHandler error:errorHandler];
}

- (NSArray *) parseRecordFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"record.spider" withExtension:@"json"]];
    NSArray * books = [spider getWeb];
    return books;
}

- (void) downloadRequestItems: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler {
    [self downloadByURLString:[NSString stringWithFormat:@"%@%@", Library.host, [self.userInfo valueForKey:@"request_link"]] success:successHandler error:errorHandler];
}

- (NSArray *) parseRequestFromData: (NSData *) data {
    NSString * html = [[NSString alloc] initWithData:[self cleanUTF8:data] encoding:NSUTF8StringEncoding];
    HTMLSpider * spider = [[HTMLSpider alloc] init];
    [spider setHTML:html];
    [spider setSpiderWithUrl: [[NSBundle mainBundle] URLForResource:@"request.spider" withExtension:@"json"]];
    NSArray * books = [spider getWeb];
    return books;
}

- (void) downloadByURLString: (NSString *) URLString success: (void (^)(AFHTTPRequestOperation *, id)) successHandler error: (void (^)(AFHTTPRequestOperation *, id)) errorHandler{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager GET:URLString parameters:nil success:successHandler failure:errorHandler];
    [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:nil error:nil];
}

- (NSArray *) getSearchMethods {
    return @[@"Keyword", @"Author", @"Title", @"Subject"];
}
- (NSString *) getSearchMethodCodeByIndex: (NSInteger) index {
    return @[@"X", @"a", @"t", @"d"][index];
}

- (NSData *)cleanUTF8:(NSData *)data {
    
    // this function is from
    // http://stackoverflow.com/questions/3485190/nsstring-initwithdata-returns-null
    //
    //
    
    iconv_t cd = iconv_open("UTF-8", "UTF-8"); // convert to UTF-8 from UTF-8
    int one = 1;
    iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one); // discard invalid characters
    
    size_t inbytesleft, outbytesleft;
    inbytesleft = outbytesleft = data.length;
    char *inbuf  = (char *)data.bytes;
    char *outbuf = malloc(sizeof(char) * data.length);
    char *outptr = outbuf;
    if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft)
        == (size_t)-1) {
        NSLog(@"this should not happen, seriously");
        return nil;
    }
    NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
    iconv_close(cd);
    free(outbuf);
    return result;
}

@end