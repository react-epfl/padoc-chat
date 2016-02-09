//
//  MHRoutingProtocol.m
//  Padoc
//
//  Created by quarta on 01/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHRoutingProtocol.h"



@interface MHRoutingProtocol () <MHConnectionsHandlerDelegate>

@property (nonatomic, strong) NSMutableArray *neighbourPeers;
@property (nonatomic, strong) MHConnectionsHandler *cHandler;
@end

@implementation MHRoutingProtocol

#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName
{
    self = [super init];
    if (self)
    {
        self.neighbourPeers = [[NSMutableArray alloc] init];
        self.cHandler = [[MHConnectionsHandler alloc] initWithServiceType:serviceType
                                                              displayName:displayName];
        
        self.cHandler.delegate = self;
        
        [[MHDiagnostics getSingleton] reset];
    }
    return self;
}

- (void)dealloc
{
    self.neighbourPeers = nil;
    self.cHandler = nil;
}

- (void)disconnect
{
    [self.neighbourPeers removeAllObjects];
    [self.cHandler disconnectFromNeighbourhood];
    
    // Can override, but must call the super method
}

- (NSString *)getOwnPeer
{
    return [self.cHandler getOwnPeer];
}

- (void)applicationWillResignActive
{
    [self.cHandler applicationWillResignActive];
}

- (void)applicationDidBecomeActive
{
    [self.cHandler applicationDidBecomeActive];
}


#pragma mark - Overridable methods
- (void)sendPacket:(MHPacket *)packet
           maxHops:(int)maxHops
             error:(NSError **)error
{
    // Must be overridden
}

- (int)hopsCountFromPeer:(NSString*)peer
{
    // Must be overridden
    return 0;
}

- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops
{
    // Must be overridden
}

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops
{
    // Must be overridden
}

#pragma mark - Connectionshandler delegate methods
- (void)cHandler:(MHConnectionsHandler *)cHandler
 failedToConnect:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mhProtocol:self failedToConnect:error];
    });
}

- (void)cHandler:(MHConnectionsHandler *)cHandler
    hasConnected:(NSString *)info
            peer:(NSString *)peer
     displayName:(NSString *)displayName
{
    // Must be overridden
}

- (void)cHandler:(MHConnectionsHandler *)cHandler
 hasDisconnected:(NSString *)info
            peer:(NSString *)peer
{
    // Must be overridden
}


- (void)cHandler:(MHConnectionsHandler *)cHandler
didReceiveDatagram:(MHDatagram *)datagram
        fromPeer:(NSString *)peer
{
    // Must be overridden
}

- (void)cHandler:(MHConnectionsHandler *)cHandler
  enteredStandby:(NSString *)info
            peer:(NSString *)peer
{
    // Must be overridden
}

- (void)cHandler:(MHConnectionsHandler *)cHandler
   leavedStandby:(NSString *)info
            peer:(NSString *)peer
{
    // Must be overridden
}
@end
