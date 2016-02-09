//
//  MH6ShotsSchedule.m
//  Padoc
//
//  Created by quarta on 04/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MH6ShotsSchedule.h"


@interface MH6ShotsSchedule ()

@property (nonatomic, readwrite) MHPacket *packet;


@end

@implementation MH6ShotsSchedule

#pragma mark - Initialization
- (instancetype)initWithPacket:(MHPacket *)packet
                      withTime:(NSTimeInterval)time
{
    self = [super init];
    if (self)
    {
        self.packet = packet;
        self.time = time;
        self.forward = YES;
    }
    
    return self;
}

- (void)dealloc
{
    self.packet = nil;
}

@end