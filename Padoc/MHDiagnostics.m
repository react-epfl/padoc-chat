//
//  MHDiagnosticsOptions.m
//  Padoc
//
//  Created by quarta on 05/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHDiagnostics.h"


@interface MHDiagnostics ()

@property (atomic) int receivedPackets;
@property (atomic) int retransmittedPackets;

@property (atomic, strong) NSMutableDictionary *networkMap;

@end


#pragma mark - Singleton static variables

static MHDiagnostics *diagnostics = nil;



@implementation MHDiagnostics

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        self.useTraceInfo = NO;
        self.useRetransmissionInfo = NO;
        self.useNeighbourInfo = NO;
        self.useNetworkLayerInfoCallbacks = NO;
        self.useNetworkLayerControlInfoCallbacks = NO;
        self.useNetworkMap = NO;
        
        self.networkMap = [[NSMutableDictionary alloc] init];
        
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    [self.networkMap removeAllObjects];
    self.networkMap = nil;
}

- (void)reset
{
    self.receivedPackets = 0;
    self.retransmittedPackets = 0;
}

#pragma mark - Singleton methods
+ (MHDiagnostics*)getSingleton
{
    if (diagnostics == nil)
    {
        // Initialize the diagnostics singleton
        diagnostics = [[MHDiagnostics alloc] init];
    }
    
    return diagnostics;
}


#pragma mark - Tracing methods

- (void)addTraceRoute:(MHPacket*)packet
         withNextPeer:(NSString*)peer
{
    if ([self useTraceInfo])
    {
        NSMutableArray *traceInfo = [packet.info objectForKey:MH_DIAGNOSTICS_TRACE];
        
        if (traceInfo == nil)
        {
            traceInfo = [[NSMutableArray alloc] init];
            [packet.info setObject:traceInfo forKey:MH_DIAGNOSTICS_TRACE];
        }
        
        [traceInfo addObject:peer];
    }
}

- (NSArray *)tracePacket:(MHPacket*)packet
{
    if ([self useTraceInfo])
    {
        NSMutableArray *traceInfo = [packet.info objectForKey:MH_DIAGNOSTICS_TRACE];
        
        return traceInfo;
    }
    
    return nil;
}



#pragma mark - Retransmission methods
- (void)increaseReceivedPackets
{
    if (self.useRetransmissionInfo)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.receivedPackets++;
        });
    }
}


- (void)increaseRetransmittedPackets
{
    if (self.useRetransmissionInfo)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.retransmittedPackets++;
        });
    }
}

// Callable by developer
- (double)getRetransmissionRatio
{
    if (self.useRetransmissionInfo && self.receivedPackets > 0)
    {
        return (double)self.retransmittedPackets / (double)self.receivedPackets;
    }

    return -1.0;
}



#pragma mark - Network map
- (BOOL)isConnectedInNetworkMap:(NSString *)localNode withNeighbourNode:(NSString *)neighbourNode
{
    if (self.useNetworkMap)
    {
        NSArray *nodes = [self.networkMap objectForKey:localNode];
        
        if (nodes != nil)
        {
            return [nodes containsObject:neighbourNode];
        }
    }

    return YES;
}

// Callable by developer
- (void)addNetworkMapNode:(NSString *)currentNode withConnectedNodes:(NSArray *)connectedNodes
{
    [self.networkMap setObject:connectedNodes forKey:currentNode];
}

- (void)clearNetworkMap
{
    [self.networkMap removeAllObjects];
}

@end