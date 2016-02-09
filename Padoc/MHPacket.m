//
//  MHPacket.m
//  Padoc
//
//  Created by quarta on 03/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHPacket.h"



@interface MHPacket ()

@property (nonatomic, readwrite, strong) NSString *tag;
@property (nonatomic, readwrite, strong) NSString *source;
@property (nonatomic, readwrite, strong) NSArray *destinations;
@property (nonatomic, readwrite, strong) NSData *data;

@property (nonatomic, readwrite, strong) NSMutableDictionary *info;

@end

@implementation MHPacket

- (instancetype)initWithSource:(NSString *)source
              withDestinations:(NSArray *)destinations
                      withData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        // Generate new packet id
        self.tag = [MHComputation makeUniqueStringFromSource:source];
        self.source = source;
        self.destinations = destinations;
        self.data = data;
        
        self.info = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.tag = [decoder decodeObjectForKey:@"tag"];
        self.source = [decoder decodeObjectForKey:@"source"];
        self.destinations = [decoder decodeObjectForKey:@"destinations"];
        self.data = [decoder decodeObjectForKey:@"data"];
        self.info = [decoder decodeObjectForKey:@"info"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.tag forKey:@"tag"];
    [encoder encodeObject:self.source forKey:@"source"];
    [encoder encodeObject:self.destinations forKey:@"destinations"];
    [encoder encodeObject:self.data forKey:@"data"];
    [encoder encodeObject:self.info forKey:@"info"];
}


- (void)dealloc
{
    [self.info removeAllObjects];
    self.info = nil;
    self.destinations = nil;
    self.data = nil;
    self.tag = nil;
    self.source = nil;
}


- (NSData *)asNSData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return data;
}


+ (MHPacket *)fromNSData:(NSData *)nsData
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:nsData];

    if([object isKindOfClass:[MHPacket class]])
    {
        MHPacket *packet = object;
        
        return packet;
    }
    else
    {
        return nil;
    }
}

@end