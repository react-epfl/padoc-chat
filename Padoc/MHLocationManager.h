//
//  MHLocationManager.h
//  Padoc
//
//  Created by quarta on 05/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHLocationManager_h
#define Padoc_MHLocationManager_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MHComputation.h"
#import "MHConfig.h"


@interface MHLocation : NSObject<NSCoding>

@property (nonatomic, readwrite) double x;
@property (nonatomic, readwrite) double y;

- (instancetype)init;

@end



@interface MHLocationManager : NSObject

- (instancetype)initWithBeaconID:(NSString*)beaconID
                         withGPS:(BOOL)useGPS
                      withBeacon:(BOOL)useBeacon;

- (void)start;
- (void)stop;

- (void)registerBeaconRegionWithUUID:(NSString *)proximityUUID;
- (void)unregisterBeaconRegionWithUUID:(NSString *)proximityUUID;

- (MHLocation*)getMPosition;
- (MHLocation*)getGPSPosition;

- (CLProximity)getProximityForUUID:(NSString *)proximityUUID;

+ (void)setBeaconIDWithPeerID:(NSString*)peerID;
+ (void)useGPS:(BOOL)use;
+ (void)useBeacon:(BOOL)use;
+ (MHLocationManager*)getSingleton;

+ (double)getDistanceFromMLocation:(MHLocation*)l1 toMLocation:(MHLocation*)l2;

+ (double)getDistanceFromGPSLocation:(MHLocation*)l1 toGPSLocation:(MHLocation*)l2;

@end


#endif
