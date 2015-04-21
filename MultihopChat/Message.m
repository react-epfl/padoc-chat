//
//  Message.m
//  MultihopChat
//
//  Created by Sven Reber on 21/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "Message.h"



@interface Message ()

@property (nonatomic, readwrite, strong) NSString *type;
@property (nonatomic, readwrite, strong) NSObject *content;

@end


@implementation Message

- (instancetype)initWithType:(NSString *)type
              withContent:(NSObject *)content
{
    self = [super init];
    if (self)
    {
        self.type = type;
        self.content = content;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.type = [decoder decodeObjectForKey:@"type"];
        self.content = [decoder decodeObjectForKey:@"content"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.content forKey:@"content"];
}


- (void)dealloc
{
    self.type = nil;
    self.content = nil;
}


@end