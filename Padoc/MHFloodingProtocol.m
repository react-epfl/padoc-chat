//
//  MHFloodingProtocol.m
//  Padoc
//
//  Created by quarta on 03/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHFloodingProtocol.h"



@interface MHFloodingProtocol ()

@property (nonatomic, strong) NSMutableArray *neighbourPeers;
@property (nonatomic, strong) MHConnectionsHandler *cHandler;

@property (nonatomic, strong) NSString *displayName;

@property (nonatomic, strong) NSMutableArray *joinedGroups;

@property (nonatomic, strong) NSMutableArray *processedPackets;

@property (copy) void (^processedPacketsCleaning)(void);

@end

@implementation MHFloodingProtocol

#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName
{
    self = [super initWithServiceType:serviceType displayName:displayName];
    if (self)
    {
        self.displayName = displayName;
        self.processedPackets = [[NSMutableArray alloc] init];
        self.joinedGroups = [[NSMutableArray alloc] init];
        
        [self.cHandler connectToNeighbourhood];
        
        MHFloodingProtocol * __weak weakSelf = self;
        [self setFctProcessedPacketsCleaning:weakSelf];
    }
    return self;
}

- (void)dealloc
{
    self.processedPackets = nil;
    self.joinedGroups = nil;
    
    self.processedPacketsCleaning = nil;
    self.displayName = nil;
}



- (void)setFctProcessedPacketsCleaning:(MHFloodingProtocol * __weak)weakSelf
{
    self.processedPacketsCleaning = ^{
        if (weakSelf)
        {
            [weakSelf.processedPackets removeAllObjects];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MHConfig getSingleton].netProcessedPacketsCleaningDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processedPacketsCleaning);
        }
    };
    
    // Every x seconds, we clean the processed packets list
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MHConfig getSingleton].netProcessedPacketsCleaningDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), self.processedPacketsCleaning);
}

- (void)disconnect
{
    [self.processedPackets removeAllObjects];
    [self.joinedGroups removeAllObjects];
    [super disconnect];
}


- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self.joinedGroups containsObject:groupName])
        {
            [self.joinedGroups addObject:groupName];
        }
    });
}

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.joinedGroups containsObject:groupName])
        {
            [self.joinedGroups removeObject:groupName];
        }
    });
}


- (void)sendPacket:(MHPacket *)packet
           maxHops:(int)maxHops
             error:(NSError **)error
{
    // Set ttl
    [packet.info setObject:[NSNumber numberWithInt:maxHops] forKey:@"ttl"];
    
    // Broadcast
    dispatch_async(dispatch_get_main_queue(), ^{
        MHDatagram *datagram = [[MHDatagram alloc] initWithData:[packet asNSData]];
        
        [self.cHandler sendDatagram:datagram toPeers:self.neighbourPeers error:error];
    });
}


- (int)hopsCountFromPeer:(NSString*)peer
{
    // The Flooding algorithm has no idea of the 
    // hops separating the local peer from another one
    // in the network (apart for the neighbourhood)
    if ([self.neighbourPeers containsObject:peer])
    {
        return 1;
    }
    else
    {
        return -1;
    }
}


#pragma mark - ConnectionsHandler delegate methods
- (void)cHandler:(MHConnectionsHandler *)cHandler
    hasConnected:(NSString *)info
            peer:(NSString *)peer
     displayName:(NSString *)displayName
{
    // Diagnostics: neighbour info
    dispatch_async(dispatch_get_main_queue(), ^{
        if([MHDiagnostics getSingleton].useNeighbourInfo)
        {
            [self.delegate mhProtocol:self neighbourConnected:@"Neighbour connected" peer:peer displayName:displayName];
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.neighbourPeers addObject:peer];
    });
}

- (void)cHandler:(MHConnectionsHandler *)cHandler
 hasDisconnected:(NSString *)info
            peer:(NSString *)peer
{
    // Diagnostics: neighbour info
    dispatch_async(dispatch_get_main_queue(), ^{
        if([MHDiagnostics getSingleton].useNeighbourInfo)
        {
            [self.delegate mhProtocol:self neighbourDisconnected:@"Neighbour disconnected" peer:peer];
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.neighbourPeers removeObject:peer];
    });
}


- (void)cHandler:(MHConnectionsHandler *)cHandler
didReceiveDatagram:(MHDatagram *)datagram
        fromPeer:(NSString *)peer
{
    MHPacket *packet = [MHPacket fromNSData:datagram.data];
    

    [self processStandardPacket:packet];
}


-(void)processStandardPacket:(MHPacket*)packet
{
    // Diagnostics: trace
    [[MHDiagnostics getSingleton] addTraceRoute:packet withNextPeer:[self getOwnPeer]];
    
    // Do not process packets whose source is this peer
    if ([packet.source isEqualToString:[self getOwnPeer]])
    {
        return;
    }
    
    // If packet has not yet been processed
    if (![self.processedPackets containsObject:packet.tag])
    {
        // Diagnostics: retransmission
        [[MHDiagnostics getSingleton] increaseReceivedPackets];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.processedPackets addObject:packet.tag];
        });
        
        NSMutableSet *intersect = [NSMutableSet setWithArray:packet.destinations];
        
        [intersect intersectSet:[NSSet setWithArray:self.joinedGroups]];

        
        // Check if local peer is a destination (if the two sets intersect)
        if (intersect.count > 0)
        {
            // Notify upper layers that a new packet is received
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate mhProtocol:self didReceivePacket:packet fromGroups:[intersect allObjects] withTraceInfo:[[MHDiagnostics getSingleton] tracePacket:packet]];
            });
        }
        
        // Diagnostics: retransmission
        [[MHDiagnostics getSingleton] increaseRetransmittedPackets];
        
        // For any packet, forwarding phase
        // Diagnostics
        if ([MHDiagnostics getSingleton].useNetworkLayerInfoCallbacks)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate mhProtocol:self forwardPacket:@"Packet forwarding" withPacket:packet];
            });
        }
        
        [self forwardPacket:packet];
    }
}


- (void)forwardPacket:(MHPacket*)packet
{
    // Decrease the ttl
    int ttl = [[packet.info objectForKey:@"ttl"] intValue];
    ttl--;
    // Update ttl
    [packet.info setObject:[NSNumber numberWithInt:ttl] forKey:@"ttl"];
    
    
    // If packet is still valid
    if (ttl > 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Broadcast to neighbourhood
            NSError *error;
            MHDatagram *datagram = [[MHDatagram alloc] initWithData:[packet asNSData]];
            [self.cHandler sendDatagram:datagram
                                toPeers:self.neighbourPeers
                                  error:&error];
        });
    }
}

@end
