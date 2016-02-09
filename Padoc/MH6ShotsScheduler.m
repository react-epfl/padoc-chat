//
//  MH6ShotsScheduler.m
//  Padoc
//
//  Created by quarta on 05/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MH6ShotsScheduler.h"



@interface MH6ShotsScheduler ()

@property (nonatomic, strong) NSMutableDictionary *routingTable;
@property (nonatomic, strong) NSMutableDictionary *neighbourRoutingTables;

@property (nonatomic, strong) NSString *localhost;

@property (nonatomic, strong) NSMutableDictionary *schedules;

@property (copy) void (^processSchedule)(void);
@property (copy) void (^overlayMaintenance)(void);
@property (copy) void (^scheduleCleaning)(void);

@end

@implementation MH6ShotsScheduler

#pragma mark - Initialization
- (instancetype)initWithRoutingTable:(NSMutableDictionary*)routingTable
                       withLocalhost:(NSString*)localhost
{
    self = [super init];
    if (self)
    {
        self.schedules = [[NSMutableDictionary alloc] init];
        self.routingTable = routingTable;
        self.localhost = localhost;
        
        self.neighbourRoutingTables = [[NSMutableDictionary alloc] init];
        
        
        MH6ShotsScheduler * __weak weakSelf = self;
        
        // Set periodically executing functions
        [self setFctProcessSchedule:weakSelf];
        [self setFctOverlayMaintenance:weakSelf];
        [self setFctScheduleCleaning:weakSelf];
    }
    
    return self;
}

- (void)dealloc
{
    self.schedules = nil;
    self.neighbourRoutingTables = nil;
    self.routingTable = nil;
    self.localhost = nil;
    
    self.scheduleCleaning = nil;
    self.processSchedule = nil;
    self.overlayMaintenance = nil;
}

- (void)setFctProcessSchedule:(MH6ShotsScheduler * __weak)weakSelf
{
    self.processSchedule = ^{
        if (weakSelf)
        {
            NSTimeInterval currTime = [[NSDate date] timeIntervalSince1970];
            
            NSArray *scheduleKeys = [weakSelf.schedules allKeys];
            for(id scheduleKey in scheduleKeys)
            {
                MH6ShotsSchedule *schedule = [weakSelf.schedules objectForKey:scheduleKey];
                
                // If we can forward and the delay is reached
                if(schedule.forward && schedule.time <= currTime)
                {
                    // Routes updating
                    [weakSelf updateRoutes:[schedule.packet.info objectForKey:@"routes"] withWeakSelf:weakSelf];
                    
                    
                    [schedule.packet.info setObject:[[MHLocationManager getSingleton] getMPosition] forKey:@"senderLocation"];
                    [schedule.packet.info setObject:weakSelf.localhost forKey:@"senderID"];
                    
                    // Diagnostics
                    if ([MHDiagnostics getSingleton].useNetworkLayerInfoCallbacks)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate mhScheduler:weakSelf forwardPacket:@"Packet forwarding" withPacket:schedule.packet];
                        });
                    }
                    
                    // Packet forwarding
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate mhScheduler:weakSelf broadcastPacket:schedule.packet];
                    });
                    
                    // We do not forward anymore
                    schedule.forward = NO;
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MH6SHOTS_PROCESSSCHEDULE_DELAY * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processSchedule);
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MH6SHOTS_PROCESSSCHEDULE_DELAY * NSEC_PER_MSEC)), dispatch_get_main_queue(), self.processSchedule);
}

- (void)setFctOverlayMaintenance:(MH6ShotsScheduler * __weak)weakSelf
{
    self.overlayMaintenance = ^{
        if (weakSelf)
        {
            if (weakSelf.neighbourRoutingTables.count > 0)
            {
                NSArray *rtKeys = [weakSelf.routingTable allKeys];
                for(id rtKey in rtKeys)
                {
                    NSNumber *g = [weakSelf.routingTable objectForKey:rtKey];
                    
                    // We look for the least number of hops toward the specified peer
                    if([g intValue] != 0)
                    {
                        int newG = 1000;
                        
                        NSArray *nrtKeys = [weakSelf.neighbourRoutingTables allKeys];
                        for(id nrtKey in nrtKeys)
                        {
                            NSDictionary *nRoutingTable = [weakSelf.neighbourRoutingTables objectForKey:nrtKey];
                            
                            NSNumber *gp = [nRoutingTable objectForKey:rtKey];
                            
                            // If the new g is less than the previous saved one
                            if(gp != nil && ([gp intValue] < newG || newG == 1000))
                            {
                                newG = [gp intValue];
                            }
                        }
                        
                        // We just increment by 1
                        [weakSelf.routingTable setObject:[NSNumber numberWithInt:newG+1] forKey:rtKey];
                    }
                }
                [weakSelf.neighbourRoutingTables removeAllObjects];
            }
            
            // We broadcast the new routing table to all neighbour peers
            MHPacket *packet = [[MHPacket alloc] initWithSource:weakSelf.localhost
                                               withDestinations:[[NSArray alloc] init]
                                                       withData:[MHComputation emptyData]];
            
            [packet.info setObject:MH6SHOTS_RT_MSG forKey:@"message-type"];
            [packet.info setObject:weakSelf.routingTable forKey:@"routing-table"];
            
            [weakSelf.delegate mhScheduler:weakSelf broadcastPacket:packet];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MHConfig getSingleton].net6ShotsOverlayMaintenanceDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.overlayMaintenance);
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MHConfig getSingleton].net6ShotsOverlayMaintenanceDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), self.overlayMaintenance);
}

- (void)setFctScheduleCleaning:(MH6ShotsScheduler * __weak)weakSelf
{
    self.scheduleCleaning = ^{
        if (weakSelf)
        {
            NSTimeInterval currTime = [[NSDate date] timeIntervalSince1970];

            NSArray *scheduleKeys = [weakSelf.schedules allKeys];
            for(id scheduleKey in scheduleKeys)
            {
                MH6ShotsSchedule *schedule = [weakSelf.schedules objectForKey:scheduleKey];
                
                // If the scheduled packet has already been forwarded and a critical delay reached,
                // we throw it
                if (!schedule.forward && currTime - schedule.time >= ([MHConfig getSingleton].netProcessedPacketsCleaningDelay / 1000.0))
                {
                    [weakSelf.schedules removeObjectForKey:scheduleKey];
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MH6SHOTS_SCHEDULECLEANING_DELAY * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.scheduleCleaning);
        }
    };

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MH6SHOTS_SCHEDULECLEANING_DELAY * NSEC_PER_MSEC)), dispatch_get_main_queue(), self.scheduleCleaning);
}



- (void)clear
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.schedules removeAllObjects];
        [self.neighbourRoutingTables removeAllObjects];
    });
}

- (void)setScheduleFromPacket:(MHPacket*)packet
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // If this node is on route for a packet destination
        if ([self isOnRoute:[packet.info objectForKey:@"routes"]])
        {
            MH6ShotsSchedule *schedule = [self.schedules objectForKey:packet.tag];
            
            if (schedule != nil)
            {
                //schedule.forward = NO;
            }
            else
            {
                NSTimeInterval t = [[NSDate date] timeIntervalSince1970] + [self getDelay:packet];
                [self.schedules setObject:[[MH6ShotsSchedule alloc] initWithPacket:packet withTime:t]
                                   forKey:packet.tag];
            }
        }
    });
}


- (BOOL)isOnRoute:(NSDictionary*)routes
{
    // If, for a particular packet destination,
    // our routing table contains a number of hops
    // less than the one specified in the packet routes
    NSArray *routeKeys = [routes allKeys];
    for (id routeKey in routeKeys)
    {
        int g = [[routes objectForKey:routeKey] intValue];
        
        NSNumber *gp = [self.routingTable objectForKey:routeKey];
        
        if(gp != nil && [gp intValue] < g)
        {
            return YES;
        }
    }
    
    return NO;
}


- (NSTimeInterval)getDelay:(MHPacket*)packet
{
    MHLocation *myLoc = [[MHLocationManager getSingleton] getMPosition];
    double d = -1.0;
    
    NSArray *targets = [self getTargets:[packet.info objectForKey:@"senderLocation"]];
    
    // We find the target from which we are the least distant
    for(id targetObj in targets)
    {
        MHLocation *target = (MHLocation*)targetObj;
        
        if([MHLocationManager getDistanceFromMLocation:myLoc toMLocation:target] < d || d == -1.0)
        {
            d = [MHLocationManager getDistanceFromMLocation:myLoc toMLocation:target];
        }
    }
    
    // From this distance, we calculate a broadcast delay
    NSTimeInterval delay = [self calculateDelayForDist:d
                          withSenderID:[packet.info objectForKey:@"senderID"]];
    
    return delay;
    
}

- (NSTimeInterval)calculateDelayForDist:(double)dist
                      withSenderID:(NSString *)senderID
{
    // The delay is computed as a combination of both GPS
    // and iBeacon parts
    
    // GPS part
    if (dist > [MHConfig getSingleton].netDeviceTransmissionRange) // There was a GPS problem (value not possible)
    {
        dist = [MHConfig getSingleton].netDeviceTransmissionRange;
    }
    
    double gpsDelay = dist / (double)[MHConfig getSingleton].netDeviceTransmissionRange;
    
    

    // iBeacons part
    CLProximity proximity = [[MHLocationManager getSingleton] getProximityForUUID:senderID];
    double ibeaconsDelay = 0.0;
    
    switch (proximity) {
        case CLProximityImmediate:
            ibeaconsDelay = 1.0;
            break;
        case CLProximityNear:
            ibeaconsDelay = 0.9;
            break;
        case CLProximityFar:
            ibeaconsDelay = 0.5;
            break;
        case CLProximityUnknown:
            ibeaconsDelay = 0.1;
            break;
        default:
            ibeaconsDelay = 0.5;
            break;
    }
    

    // Final delay
    double delayFraction = MH6SHOTS_GPS_FRACTION*gpsDelay + MH6SHOTS_IBEACONS_FRACTION*ibeaconsDelay;
    
    // In milliseconds
    double delay = (double)[MHConfig getSingleton].net6ShotsPacketForwardDelayRange*delayFraction + (double)[MHConfig getSingleton].net6ShotsPacketForwardDelayBase;
    
    // Transform to NSTimeInterval (seconds)
    return delay / 1000.0;
}

-(NSArray*)getTargets:(MHLocation*)senderLoc
{
    // We compute 6 targets around the sender node position
    NSMutableArray *targets = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < 6; i++)
    {
        MHLocation *target = [[MHLocation alloc] init];
        target.x = senderLoc.x + sin((M_PI/6) + i*(M_PI/3)) * [MHConfig getSingleton].netDeviceTransmissionRange;
        target.y = senderLoc.y + cos((M_PI/6) + i*(M_PI/3)) * [MHConfig getSingleton].netDeviceTransmissionRange;
    }
    
    return targets;
}


-(void)updateRoutes:(NSMutableDictionary*)routes withWeakSelf:(MH6ShotsScheduler * __weak)weakSelf
{
    // We update the routes of the packet based on our
    // routing table (we take the smallest for each destination)
    NSArray *routeKeys = [routes allKeys];
    for (id routeKey in routeKeys)
    {
        int g = [[routes objectForKey:routeKey] intValue];
        
        NSNumber *gp = [weakSelf.routingTable objectForKey:routeKey];
        
        if(gp != nil && [gp intValue] < g)
        {
            [routes setObject:gp forKey:routeKey];
        }
    }
}


#pragma mark - Maintenance methods
- (void)addNeighbourRoutingTable:(NSMutableDictionary*)routingTable
                      withSource:(NSString*)source
{
    // Add new neighbour routing table
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![source isEqualToString:self.localhost])
        {
            [self.neighbourRoutingTables setObject:routingTable forKey:source];
        }
    });
}

@end