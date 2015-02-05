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

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.host = @"http://lib.cityu.edu.hk";
    }
    return self;
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


- (void) searchBooksWithString:(NSString *)string success: successHandler error: errorHandler {
    NSArray * keys = [NSArray arrayWithObjects:@"searchtype", @"searcharg", @"searchscope", @"SORT", @"extended", @"SUBMIT", nil];
    NSArray * values = [NSArray arrayWithObjects:@"X", string, @"8", @"D", @"0", @"Search", nil];
    NSString * queryString = [self buildQueryString:keys values:values];
    NSString * URLString = [NSString stringWithFormat:@"http://lib.cityu.edu.hk/search~S8/?%@", queryString];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager GET:URLString parameters:nil success:successHandler failure:errorHandler];
    [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:nil error:nil];
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
        NSString * author_publisher = [[book valueForKey:@"title_author_publisher"] stringByReplacingOccurrencesOfString:[book valueForKey:@"title"] withString:@""];
        NSMutableArray * tokens = [NSMutableArray arrayWithArray:[author_publisher componentsSeparatedByString:@"\n"]];
        [tokens removeObject:@""];
        if ([tokens count] >= 2) {
            // found author and publisher
            [book setObject:tokens[0] forKey:@"author"];
            [book setObject:tokens[1] forKey:@"publisher"];
        }
        [book removeObjectForKey:@"title_author_publisher"];
    }
    return books;
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