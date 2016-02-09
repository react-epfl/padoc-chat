//
//  MH6ShotsSchedule.h
//  Padoc
//
//  Created by quarta on 04/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MH6ShotsSchedule_h
#define Padoc_MH6ShotsSchedule_h

#import "MHPacket.h"

@interface MH6ShotsSchedule : NSObject


@property (nonatomic, readonly) MHPacket *packet;

@property (nonatomic, readwrite) NSTimeInterval time;
@property (nonatomic, readwrite) BOOL forward;

#pragma mark - Initialization
- (instancetype)initWithPacket:(MHPacket *)packet
                      withTime:(NSTimeInterval)time;


@end

#endif
