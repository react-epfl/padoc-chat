//
//  MHConnectionsHandler.h
//  consoleViewer
//
//  Created by quarta on 25/03/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef consoleViewer_MHConnectionsHandler_h
#define consoleViewer_MHConnectionsHandler_h


#import <Foundation/Foundation.h>
#import "MHMultipeerWrapper.h"
#import "MHConnectionBuffer.h"
#import "MHDatagram.h"


#define MHCONNECTIONSHANDLER_BACKGROUND_SIGNAL @"[{_-background_sgn-_}]"
#define MHCONNECTIONSHANDLER_CHECK_TIME 60

/**
 
 This layer has 2 purposes:
 - Limit the outgoing trafic throughput, so that the
 low level API does not get saturated (and errors occur).
 
 - Hide to the above layers the disconnection/reconnection process
 that randomly occur between peers (for example, when switching background tasks).
 Messages sent during that short period are buffered and sent later.
 
 **/


@protocol MHConnectionsHandlerDelegate;

@interface MHConnectionsHandler : NSObject

#pragma mark - Properties
@property (nonatomic, weak) id<MHConnectionsHandlerDelegate> delegate;


#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName;

- (void)connectToNeighbourhood;

- (void)disconnectFromNeighbourhood;


- (void)sendDatagram:(MHDatagram *)datagram
             toPeers:(NSArray *)peers
               error:(NSError **)error;

- (NSString *)getOwnPeer;

#pragma mark - Background handling
- (void)applicationWillResignActive;

- (void)applicationDidBecomeActive;

@end

@protocol MHConnectionsHandlerDelegate <NSObject>

@required
- (void)cHandler:(MHConnectionsHandler *)cHandler
    hasConnected:(NSString *)info
            peer:(NSString *)peer
     displayName:(NSString *)displayName;

- (void)cHandler:(MHConnectionsHandler *)cHandler
 hasDisconnected:(NSString *)info
            peer:(NSString *)peer;

- (void)cHandler:(MHConnectionsHandler *)cHandler
 failedToConnect:(NSError *)error;

- (void)cHandler:(MHConnectionsHandler *)cHandler
didReceiveDatagram:(MHDatagram *)datagram
        fromPeer:(NSString *)peer;

- (void)cHandler:(MHConnectionsHandler *)cHandler
  enteredStandby:(NSString *)info
            peer:(NSString *)peer;

- (void)cHandler:(MHConnectionsHandler *)cHandler
   leavedStandby:(NSString *)info
            peer:(NSString *)peer;
@end



#endif
