//
//  MHDiagnosticsOptions.h
//  Padoc
//
//  Created by quarta on 05/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHDiagnosticsOptions_h
#define Padoc_MHDiagnosticsOptions_h


#import <Foundation/Foundation.h>
#import "MHPacket.h"

#define MH_DIAGNOSTICS_TRACE  @"[{_-diagnostics-trace-_}]"


@interface MHDiagnostics : NSObject

@property (nonatomic, readwrite) BOOL useTraceInfo;
@property (nonatomic, readwrite) BOOL useRetransmissionInfo;
@property (nonatomic, readwrite) BOOL useNeighbourInfo;
@property (nonatomic, readwrite) BOOL useNetworkLayerInfoCallbacks;
@property (nonatomic, readwrite) BOOL useNetworkLayerControlInfoCallbacks;
@property (nonatomic, readwrite) BOOL useNetworkMap;


- (instancetype)init;

+ (MHDiagnostics*)getSingleton;

- (void)reset;

#pragma mark - Tracing methods
- (void)addTraceRoute:(MHPacket*)packet withNextPeer:(NSString*)peer;
- (NSArray *)tracePacket:(MHPacket*)packet;


#pragma mark - Retransmission methods
- (void)increaseReceivedPackets;
- (void)increaseRetransmittedPackets;

// Callable by developer
- (double)getRetransmissionRatio;


#pragma mark - Network map
- (BOOL)isConnectedInNetworkMap:(NSString *)localNode withNeighbourNode:(NSString *)neighbourNode;
   
// Callable by developer
- (void)addNetworkMapNode:(NSString *)currentNode withConnectedNodes:(NSArray *)connectedNodes;
- (void)clearNetworkMap;

@end


#endif
