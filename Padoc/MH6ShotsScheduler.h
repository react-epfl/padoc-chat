//
//  MH6ShotsScheduler.h
//  Padoc
//
//  Created by quarta on 05/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MH6ShotsScheduler_h
#define Padoc_MH6ShotsScheduler_h

#import <Foundation/Foundation.h>
#import "MHDiagnostics.h"
#import "MHLocationManager.h"
#import "MH6ShotsSchedule.h"
#import "MHPacket.h"

#import "MHConfig.h"


#define MH6SHOTS_PROCESSSCHEDULE_DELAY 50

#define MH6SHOTS_SCHEDULECLEANING_DELAY 5000

#define MH6SHOTS_GPS_FRACTION 0.5
#define MH6SHOTS_IBEACONS_FRACTION 0.5

#define MH6SHOTS_RT_MSG @"-[routingtable-msg]-"


@protocol MH6ShotsSchedulerDelegate;

@interface MH6ShotsScheduler : NSObject

@property (nonatomic, weak) id<MH6ShotsSchedulerDelegate> delegate;

#pragma mark - Initialization
- (instancetype)initWithRoutingTable:(NSMutableDictionary*)routingTable
                       withLocalhost:(NSString*)localhost;

- (void)clear;


- (void)setScheduleFromPacket:(MHPacket*)packet;

- (void)addNeighbourRoutingTable:(NSMutableDictionary*)routingTable
                      withSource:(NSString*)source;

@end

/**
 The delegate for the MH6ShotsScheduler class.
 */
@protocol MH6ShotsSchedulerDelegate <NSObject>

@required
- (void)mhScheduler:(MH6ShotsScheduler *)mhScheduler
    broadcastPacket:(MHPacket*)packet;


#pragma mark - Diagnostics info callbacks
- (void)mhScheduler:(MH6ShotsScheduler *)mhScheduler
      forwardPacket:(NSString *)info
         withPacket:(MHPacket *)packet;

@end

#endif
