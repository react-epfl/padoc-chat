//
//  MHController.h
//  Padoc
//
//  Created by quarta on 02/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHController_h
#define Padoc_MHController_h


#import <Foundation/Foundation.h>
#import "MHRoutingProtocol.h"
#import "MHMessage.h"

// Protocols
#import "MH6ShotsProtocol.h"
#import "MHFloodingProtocol.h"
#import "MHCBSProtocol.h"


typedef enum MHRoutingProtocols
{
    MH6ShotsRoutingProtocol,
    MHCBSRoutingProtocol,
    MHFloodingRoutingProtocol
}MHRoutingProtocols;

@protocol MHControllerDelegate;

@interface MHController : NSObject

#pragma mark - Properties


@property (nonatomic, weak) id<MHControllerDelegate> delegate;


#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName
                withRoutingProtocol:(MHRoutingProtocols)protocol;


- (void)disconnect;

- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops;

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops;

- (void)sendMessage:(MHMessage *)message
     toDestinations:(NSArray *)destinations
            maxHops:(int)maxHops
              error:(NSError **)error;


- (NSString *)getOwnPeer;

- (int)hopsCountFromPeer:(NSString*)peer;



// Background Mode methods
- (void)applicationWillResignActive;

- (void)applicationDidBecomeActive;

// Termination method
- (void)applicationWillTerminate;


@end

/**
 The delegate for the MHMulticastController class.
 */
@protocol MHControllerDelegate <NSObject>

@required
- (void)mhController:(MHController *)mhController
     failedToConnect:(NSError *)error;

- (void)mhController:(MHController *)mhController
   didReceiveMessage:(MHMessage *)message
          fromGroups:(NSArray *)groups
       withTraceInfo:(NSArray *)traceInfo;

#pragma mark - Diagnostics info callbacks
- (void)mhController:(MHController *)mhController
       forwardPacket:(NSString *)info
         withMessage:(MHMessage *)message
          fromSource:(NSString *)peer;

- (void)mhController:(MHController *)mhController
neighbourConnected:(NSString *)info
                peer:(NSString *)peer
         displayName:(NSString *)displayName;

- (void)mhController:(MHController *)mhController
neighbourDisconnected:(NSString *)info
                peer:(NSString *)peer;

- (void)mhController:(MHController *)mhController
         joinedGroup:(NSString *)info
                peer:(NSString *)peer
         displayName:(NSString *)displayName
               group:(NSString *)group;
@end


#endif
