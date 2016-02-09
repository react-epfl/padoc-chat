//
//  MH6ShotsProtocol.h
//  Padoc
//
//  Created by quarta on 04/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MH6ShotsProtocol_h
#define Padoc_MH6ShotsProtocol_h

#import "MHRoutingProtocol.h"
#import "MHLocationManager.h"
#import "MH6ShotsScheduler.h"



#define MH6SHOTS_JOIN_MSG @"-[join-msg]-"
#define MH6SHOTS_LEAVE_MSG @"-[leave-msg]-"

@interface MH6ShotsProtocol : MHRoutingProtocol


#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName;


- (void)disconnect;

- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops;

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops;

- (void)sendPacket:(MHPacket *)packet
           maxHops:(int)maxHops
             error:(NSError **)error;


@end


#endif
