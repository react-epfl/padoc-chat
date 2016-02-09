//
//  MHRoutingProtocol.h
//  Padoc
//
//  Created by quarta on 01/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHRoutingProtocol_h
#define Padoc_MHRoutingProtocol_h


#import <Foundation/Foundation.h>
#import "MHConnectionsHandler.h"
#import "MHPacket.h"
#import "MHDatagram.h"

#import "MHConfig.h"

// Diagnostics
#import "MHDiagnostics.h"



@protocol MHRoutingProtocolDelegate;

@interface MHRoutingProtocol : NSObject

#pragma mark - Properties

@property(nonatomic, weak) id<MHRoutingProtocolDelegate> delegate;


#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName;

- (NSString *)getOwnPeer;


- (void)applicationWillResignActive;

- (void)applicationDidBecomeActive;


#pragma mark - Overridable methods
- (void)disconnect;

- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops;

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops;

- (void)sendPacket:(MHPacket *)packet
           maxHops:(int)maxHops
             error:(NSError **)error;

- (int)hopsCountFromPeer:(NSString*)peer;

@end


@protocol MHRoutingProtocolDelegate <NSObject>

@required
- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
   failedToConnect:(NSError *)error;

- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
  didReceivePacket:(MHPacket *)packet
        fromGroups:(NSArray *)groups
     withTraceInfo:(NSArray *)traceInfo;


#pragma mark - Diagnostics info callbacks
- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
     forwardPacket:(NSString *)info
        withPacket:(MHPacket *)packet;

- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
neighbourConnected:(NSString *)info
              peer:(NSString *)peer
       displayName:(NSString *)displayName;

- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
neighbourDisconnected:(NSString *)info
              peer:(NSString *)peer;

- (void)mhProtocol:(MHRoutingProtocol *)mhProtocol
       joinedGroup:(NSString *)info
              peer:(NSString *)peer
       displayName:(NSString *)displayName
             group:(NSString *)group;
@end


#endif
