//
//  MHParameters.m
//  Padoc
//
//  Created by quarta on 17/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//



#import "MHConfig.h"


@interface MHConfig ()


@end


#pragma mark - Singleton static variables

static MHConfig *params = nil;



@implementation MHConfig

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        [self setDefaults];
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)setDefaults
{
    // Link layer
    self.linkHeartbeatSendDelay = 2000;
    self.linkMaxHeartbeatFails = 4;
    
    self.linkDatagramSendDelay = 250;
    self.linkMaxDatagramSize = 3000;
    
    self.linkBackgroundDatagramSendDelay = 20;
    
    
    // Network layer
    self.netPacketTTL = 100;
    self.netProcessedPacketsCleaningDelay = 30000;
    
    self.netCBSPacketForwardDelayRange = 100;
    self.netCBSPacketForwardDelayBase = 30;
    
    self.net6ShotsControlPacketForwardDelayRange = 50;
    self.net6ShotsControlPacketForwardDelayBase = 20;
    
    self.net6ShotsPacketForwardDelayRange = 100;
    self.net6ShotsPacketForwardDelayBase = 30;
    
    self.net6ShotsOverlayMaintenanceDelay = 5000;
    
    self.netDeviceTransmissionRange = 40;
}

#pragma mark - Singleton methods
+ (MHConfig*)getSingleton
{
    if (params == nil)
    {
        // Initialize the parameters singleton
        params = [[MHConfig alloc] init];
    }
    
    return params;
}

@end