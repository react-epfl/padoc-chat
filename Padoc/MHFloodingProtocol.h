//
//  MHFloodingProtocol.h
//  Padoc
//
//  Created by quarta on 03/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHFloodingProtocol_h
#define Padoc_MHFloodingProtocol_h

#import "MHRoutingProtocol.h"


@interface MHFloodingProtocol : MHRoutingProtocol


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


- (void)processStandardPacket:(MHPacket*)packet;
- (void)forwardPacket:(MHPacket*)packet;

@end

#endif
