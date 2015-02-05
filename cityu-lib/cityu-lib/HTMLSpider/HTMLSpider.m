//
//  HTMLSpider.m
//  cityu-lib
//
//  Created by Xinhong LIU on 4/2/15.
//  Copyright (c) 2015 ParseCool. All rights reserved.
//

#import "HTMLSpider.h"

@implementation HTMLSpider

- (void) setHTML: (NSString *) html {
    self.html = html;
}

- (NSString *) getHTML {
    return self.html;
}

- (void) setSpiderWithUrl: (NSURL *) url {
    NSString * json = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    id spider = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    self.spider = spider;
}

- (NSArray *) getWeb {
    NSMutableArray * results = [[NSMutableArray alloc] init];
    
    HTMLDocument * document = [HTMLDocument documentWithString:self.html];
    NSDictionary * spiderUnit = [self.spider valueForKey:@"unit"];
    NSArray * units = [document nodesMatchingSelector: [spiderUnit valueForKey:@"selector"]];
    for (HTMLElement * unit in units) {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        NSArray * spiderProperties = [self.spider valueForKey:@"property"];
        for (NSDictionary * spiderProperty in spiderProperties) {
            NSString * name = [spiderProperty valueForKey:@"name"];
            NSString * selector = [spiderProperty valueForKey:@"selector"];
            NSInteger index = [[spiderProperty valueForKey:@"index"] integerValue];
            NSString * attribute = [spiderProperty valueForKey:@"attribute"];
            NSArray * elems = [unit nodesMatchingSelector:selector];
            if ([elems count] == 0) {
                continue;
            }
            HTMLElement * elem = [elems objectAtIndex:index];
            NSString * value;
            if ([attribute  isEqual: @"text"]) {
                value = elem.textContent;
            } else {
                value = elem.attributes[attribute];
            }
            [dict setObject:value forKey:name];
        }
        [results addObject:dict];
    }
    
    return results;
}

@end
