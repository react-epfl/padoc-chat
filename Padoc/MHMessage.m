//
//  MHMessage.m
//  Padoc
//
//  Created by quarta on 03/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHMessage.h"

@interface MHMessage ()

@property (nonatomic, readwrite, strong) NSData *data;

@end

@implementation MHMessage

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        self.data = data;
        self.sin = NO;
        self.ack = NO;
        self.seqNumber = 0;
        self.ackNumber = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.data = [decoder decodeObjectForKey:@"data"];
        self.seqNumber = [decoder decodeIntegerForKey:@"seqNumber"];
        self.ackNumber = [decoder decodeIntegerForKey:@"ackNumber"];
        self.sin = [decoder decodeBoolForKey:@"sin"];
        self.ack = [decoder decodeBoolForKey:@"ack"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.data forKey:@"data"];
    [encoder encodeInteger:self.seqNumber forKey:@"seqNumber"];
    [encoder encodeInteger:self.ackNumber forKey:@"ackNumber"];
    [encoder encodeBool:self.sin forKey:@"sin"];
    [encoder encodeBool:self.ack forKey:@"ack"];
}


- (void)dealloc
{
    self.data = nil;
}


- (NSData *)asNSData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return data;
}


+ (MHMessage *)fromNSData:(NSData *)nsData
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:nsData];
    
    if([object isKindOfClass:[MHMessage class]])
    {
        MHMessage *message = object;
        
        return message;
    }
    else
    {
        return nil;
    }
}

@end
