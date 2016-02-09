//
//  MHParameters.h
//  Padoc
//
//  Created by quarta on 17/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHParameters_h
#define Padoc_MHParameters_h

#import <Foundation/Foundation.h>


@interface MHConfig : NSObject

#pragma mark - Link layer
@property (nonatomic, readwrite) int linkHeartbeatSendDelay; // in milliseconds (default 2000)
@property (nonatomic, readwrite) int linkMaxHeartbeatFails; // default 5

@property (nonatomic, readwrite) int linkDatagramSendDelay; // in ms (default 250)
@property (nonatomic, readwrite) int linkMaxDatagramSize; // default 3000

@property (nonatomic, readwrite) int linkBackgroundDatagramSendDelay; // in ms (default 20)


#pragma mark - Network layer
@property (nonatomic, readwrite) int netPacketTTL; // default 100
@property (nonatomic, readwrite) int netProcessedPacketsCleaningDelay; // in ms (default 30000)

@property (nonatomic, readwrite) int netCBSPacketForwardDelayRange; // in ms (default 100)
@property (nonatomic, readwrite) int netCBSPacketForwardDelayBase; // in ms (default 30)

@property (nonatomic, readwrite) int net6ShotsControlPacketForwardDelayRange; // in ms (default 50)
@property (nonatomic, readwrite) int net6ShotsControlPacketForwardDelayBase; // in ms (default 20)

@property (nonatomic, readwrite) int net6ShotsPacketForwardDelayRange; // in ms (default 100)
@property (nonatomic, readwrite) int net6ShotsPacketForwardDelayBase; // in ms (default 30)

@property (nonatomic, readwrite) int net6ShotsOverlayMaintenanceDelay; // in ms (default 5000)


@property (nonatomic, readwrite) int netDeviceTransmissionRange; // in meters (default 40)

- (instancetype)init;

+ (MHConfig*)getSingleton;

- (void)setDefaults;


@end

#endif
