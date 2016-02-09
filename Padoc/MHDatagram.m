//
//  MHDatagram.m
//  Padoc
//
//  Created by quarta on 13/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHDatagram.h"



@interface MHDatagram ()


@property (nonatomic, readwrite, strong) NSMutableDictionary *info;

@end

@implementation MHDatagram

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        self.data = data;
        
        self.info = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.data = [decoder decodeObjectForKey:@"data"];
        self.tag = [decoder decodeObjectForKey:@"tag"];
        self.noChunk = [decoder decodeIntForKey:@"noChunk"];
        self.chunksNumber = [decoder decodeIntForKey:@"chunksNumber"];
        self.info = [decoder decodeObjectForKey:@"info"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.data forKey:@"data"];
    [encoder encodeObject:self.info forKey:@"info"];
    [encoder encodeObject:self.tag forKey:@"tag"];
    [encoder encodeInt:self.chunksNumber forKey:@"chunksNumber"];
    [encoder encodeInt:self.noChunk forKey:@"noChunk"];
}


- (void)dealloc
{
    [self.info removeAllObjects];
    self.info = nil;
    self.data = nil;
    self.tag = nil;
}


- (NSData *)asNSData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return data;
}


+ (MHDatagram *)fromNSData:(NSData *)nsData
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:nsData];
    
    if([object isKindOfClass:[MHDatagram class]])
    {
        MHDatagram *datagram = object;
        
        return datagram;
    }
    else
    {
        return nil;
    }
}

@end