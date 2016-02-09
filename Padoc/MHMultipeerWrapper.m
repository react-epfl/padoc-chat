//
//  MHNodeManager.m
//  Padoc
//
//  Created by quarta on 16/03/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHMultipeerWrapper.h"


@interface MHMultipeerWrapper () <MHPeerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

// Public Properties
@property (nonatomic, readwrite) BOOL serviceStarted;
@property (nonatomic, readwrite, strong) NSString *serviceType;

@property (nonatomic, strong) MHPeer *mhPeer;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) NSMutableDictionary *dictInfo;

@property (nonatomic, strong) NSMutableDictionary *neighbourPeers;
@property (nonatomic, strong) NSMutableArray *connectedPeers;

@property (copy) void (^restartService)(void);
@end

@implementation MHMultipeerWrapper

#pragma mark - Life Cycle

- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName
{
    self = [super init];
    if (self)
    {
        self.serviceType = [NSString stringWithFormat:@"%@%@", MH_SERVICE_PREFIX, serviceType];
        self.mhPeer = [MHPeer getOwnMHPeerWithDisplayName:displayName];
        self.neighbourPeers = [[NSMutableDictionary alloc] init];
        self.connectedPeers = [[NSMutableArray alloc] init];
        
        MHMultipeerWrapper * __weak weakSelf = self;
        [self setFctRestartService:weakSelf];
    }
    return self;
}

- (void)dealloc
{
    // Will clean up the sessions and browsers properly
    [self disconnectFromNeighbourhood];
    
    self.neighbourPeers = nil;
    self.connectedPeers = nil;
    
    self.restartService = nil;
    self.dictInfo = nil;
    self.browser = nil;
    self.advertiser = nil;
    self.mhPeer = nil;
    self.serviceType = nil;
    
}


- (void)setFctRestartService:(MHMultipeerWrapper * __weak)weakSelf
{
    // Sender side
    self.restartService = ^{
        if(weakSelf)
        {
            // We must restarting the service, otherwise
            // the advertiser and brower do not work properly
            if(weakSelf.serviceStarted)
            {
                [weakSelf stopService];
                [weakSelf connectToNeighbourhood];
            }
            
            // Dispatch after y seconds
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), weakSelf.restartService);
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), weakSelf.restartService);
}

#pragma mark - Membership

- (void)connectToNeighbourhood
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // If we're already joined, then don't try again. This causes crashes.
        
        if (!self.serviceStarted)
        {
            // Simultaneously advertise and browse at the same time
            [self.advertiser startAdvertisingPeer];
            [self.browser startBrowsingForPeers];
            
            self.serviceStarted = YES;
        }
    });
}

- (void)stopService
{
    [self.advertiser stopAdvertisingPeer];
    [self.browser stopBrowsingForPeers];
    
    // Must nil out these because if we try to reconnect, we need to recreate them
    // Else it fails to connect
    self.advertiser = nil;
    self.browser = nil;
    
    self.serviceStarted = NO;
}

- (void)disconnectFromNeighbourhood
{
    if(self.serviceStarted)
    {
        [self stopService];
        
        // Disconnect every peer
        for (id peerObj in self.neighbourPeers)
        {
            MHPeer *peer = [self getMHPeerFromId:(NSString *)peerObj];
            
            [peer disconnect];
        }
        
        [self.neighbourPeers removeAllObjects];
        [self.connectedPeers removeAllObjects];
    }
}

#pragma mark - Communicate

- (void)sendDatagram:(MHDatagram *)datagram
             toPeers:(NSArray *)peers
               error:(NSError **)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Send data to all the specified peers, if available
        for (id peerKey in peers)
        {
            if ([self peerAvailable:peerKey])
            {
                MHPeer *peer = [self getMHPeerFromId:(NSString *)peerKey];
                
                [peer sendDatagram:datagram
                             error:error];
            }
        }
    });
}

- (NSString *)getOwnPeer
{
    return self.mhPeer.mhPeerID;
}


#pragma mark - Properties

- (NSDictionary *)dictInfo
{
    if (!_dictInfo)
    {
        NSAssert(self.serviceType, @"No service type. You must initialize this class using the custom intializers.");
        
        _dictInfo = [[NSMutableDictionary alloc] init];
        [_dictInfo setObject:self.mhPeer.mhPeerID forKey:@"PadocID"];
        [_dictInfo setObject:self.mhPeer.displayName forKey:@"PadocDisplayName"];
    }
    return _dictInfo;
}

- (MCNearbyServiceAdvertiser *)advertiser
{
    if (!_advertiser)
    {
        NSAssert(self.serviceType, @"No service type. You must initialize this class using the custom intializers.");
        
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.mhPeer.mcPeerID
                                                        discoveryInfo:self.dictInfo
                                                          serviceType:self.serviceType];
        _advertiser.delegate = self;
    }
    return _advertiser;
}


- (MCNearbyServiceBrowser *)browser
{
    if (!_browser)
    {
        NSAssert(self.serviceType, @"No service type. You must initialize this class using the custom intializers.");
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.mhPeer.mcPeerID
                                                    serviceType:self.serviceType];
        _browser.delegate = self;
    }
    return _browser;
}

#pragma mark - MHPeer Delegate

- (void)mhPeer:(MHPeer *)mhPeer hasConnected:(NSString *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.connectedPeers addObject:mhPeer.mhPeerID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate mcWrapper:self hasConnected:info peer:mhPeer.mhPeerID displayName:mhPeer.displayName];
        });
    });
}

- (void)mhPeer:(MHPeer *)mhPeer hasDisconnected:(NSString *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self peerAvailable:mhPeer.mhPeerID])
        {
            NSString *mhPeerID = mhPeer.mhPeerID;
            
            [mhPeer disconnect];
            
            [self.neighbourPeers removeObjectForKey:mhPeerID];
            
            
            if ([self peerConnected:mhPeerID])
            {
                [self.connectedPeers removeObject:mhPeerID];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate mcWrapper:self hasDisconnected:info peer:mhPeerID];
                });
            }
        }
    });
}



- (void)mhPeer:(MHPeer *)mhPeer didReceiveDatagram:(MHDatagram *)datagram
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mcWrapper:self didReceiveDatagram:datagram fromPeer:mhPeer.mhPeerID];
    });
}


#pragma mark - Advertiser Delegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *info = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:context];
        
        // Diagnostics: network map
        if([[MHDiagnostics getSingleton] isConnectedInNetworkMap:self.mhPeer.displayName
                                               withNeighbourNode:[info objectForKey:@"PadocDisplayName"]])
        {
            // Only accept invitations with IDs lower than the current host
            // If both people accept invitations, then connections are lost
            // However, this should always be the case since we only send invites in one direction
            NSString *padocID = [info objectForKey:@"PadocID"];
            
            if ([self.mhPeer.mhPeerID compare:padocID] == NSOrderedDescending)
            {
                if([self peerAvailable:padocID]) // peer has already been disconnected
                {
                    MHPeer *peer = [self.neighbourPeers objectForKey:padocID];
                    [peer disconnect];
                    
                    [self.neighbourPeers removeObjectForKey:padocID];
                    
                    
                    if ([self peerConnected:padocID])
                    {
                        [self.connectedPeers removeObject:padocID];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate mcWrapper:self hasDisconnected:@"Heartbeat failed" peer:padocID];
                        });
                    }
                    
                }
                
                MCSession *session = [self addNewNeighbourPeer:peerID withInfo:info];
                
                // We accept the invitation
                invitationHandler(YES, session);
            }
        }
    });
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mcWrapper:self failedToConnect:error];
    });
}

#pragma mark - Browser Delegate

- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Diagnostics: network map
        if([[MHDiagnostics getSingleton] isConnectedInNetworkMap:self.mhPeer.displayName
                                                withNeighbourNode:[info objectForKey:@"PadocDisplayName"]])
        {
            // Whenever we find a peer, let's just send them an invitation
            // But only send invites one way
            NSString *padocID = [info objectForKey:@"PadocID"];
            
            
            if ([self.mhPeer.mhPeerID compare:padocID] == NSOrderedAscending)
            {
                if(![self peerAvailable:padocID]) // peer has already been disconnected
                {
                    MCSession *session = [self addNewNeighbourPeer:peerID withInfo:info];
                    
                    // We set the peer discovery information
                    NSData *context = [NSKeyedArchiver archivedDataWithRootObject:self.dictInfo];
                    
                    // A very long timeout is used, anyway the heartbeat
                    // mechanism ensures that if the connection has not
                    // been established, peers are disconnected
                    [browser invitePeer:peerID
                              toSession:session
                            withContext:context
                                timeout:MH_INVITATION_TIMEOUT];
                }
            }
        }
    });
}

- (MCSession *)addNewNeighbourPeer:(MCPeerID *)peerID withInfo:(NSDictionary *)info
{
    MHPeer *peer = [[MHPeer alloc] initWithDisplayName:[info objectForKey:@"PadocDisplayName"]
                                       withOwnMCPeerID:self.mhPeer.mcPeerID
                                       withOwnMHPeerID:self.mhPeer.mhPeerID
                                          withMCPeerID:peerID
                                          withMHPeerID:[info objectForKey:@"PadocID"]];
    peer.delegate = self;
    
    
    [self.neighbourPeers setObject:peer forKey:peer.mhPeerID];
    
    return peer.session;
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    // Nothing to do
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mcWrapper:self failedToConnect:error];
    });
}

         
#pragma mark - Helper methods
- (MHPeer *)getMHPeerFromId:(NSString *)peerID
{
    MHPeer *peer = [self.neighbourPeers objectForKey:peerID];
    
    if (peer == nil)
    {
        [NSException raise:@"Cannot find peer having the specified id" format:@"%@", peerID];
    }
    
    return peer;
}

- (BOOL)peerAvailable:(NSString *)peer
{
    return [self.neighbourPeers objectForKey:peer] != nil;
}

- (BOOL)peerConnected:(NSString *)peer
{
    return [self.connectedPeers containsObject:peer];
}


@end
