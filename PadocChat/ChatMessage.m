//
//  ChatMessage.m
//  PadocChat
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

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.source = [decoder decodeObjectForKey:@"source"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.content = [decoder decodeObjectForKey:@"content"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.source forKey:@"source"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.content forKey:@"content"];
}

- (void)dealloc {
    self.source = nil;
    self.date = nil;
    self.content = nil;
}

@end