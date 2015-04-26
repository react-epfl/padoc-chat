//
//  ChatMessage.m
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "ChatMessage.h"


@interface ChatMessage ()

@property (nonatomic, readwrite, strong) NSString *source;
@property (nonatomic, readwrite, strong) NSDate *date;
@property (nonatomic, readwrite, strong) NSString *content;

@end


@implementation ChatMessage

- (instancetype)initWithSource:(NSString *)source
                      withDate:(NSDate *) date
                   withContent:(NSString *)content {
    self = [super init];
    if (self) {
        self.source = source;
        self.date = date;
        self.content = content;
    }
    return self;
}

- (void)dealloc {
    self.source = nil;
    self.date = nil;
    self.content = nil;
}

@end