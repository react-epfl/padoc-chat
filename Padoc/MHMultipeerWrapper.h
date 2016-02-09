//
//  MHNodeManager.h
//  Padoc
//
//  Created by quarta on 16/03/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHMultipeerWrapper_h
#define Padoc_MHMultipeerWrapper_h


#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MHDatagram.h"
#import "MHDiagnostics.h"
#import "MHPeer.h"

#define MH_SERVICE_PREFIX @"mh-"
#define MH_INVITATION_TIMEOUT 1000

@protocol MHMultipeerWrapperDelegate;

@interface MHMultipeerWrapper : NSObject

#pragma mark - Properties
@property (nonatomic, weak) id<MHMultipeerWrapperDelegate> delegate;
@property (nonatomic, readonly, strong) NSString *serviceType;


#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName;

- (void)connectToNeighbourhood;

- (void)disconnectFromNeighbourhood;

- (void)sendDatagram:(MHDatagram *)datagram
             toPeers:(NSArray *)peers
               error:(NSError **)error;

- (NSString *)getOwnPeer;

@end

@protocol MHMultipeerWrapperDelegate <NSObject>

@required
- (void)mcWrapper:(MHMultipeerWrapper *)mcWrapper
     hasConnected:(NSString *)info
             peer:(NSString *)peer
      displayName:(NSString *)displayName;

- (void)mcWrapper:(MHMultipeerWrapper *)mcWrapper
  hasDisconnected:(NSString *)info
             peer:(NSString *)peer;

- (void)mcWrapper:(MHMultipeerWrapper *)mcWrapper
  failedToConnect:(NSError *)error;

- (void)mcWrapper:(MHMultipeerWrapper *)mcWrapper
didReceiveDatagram:(MHDatagram *)datagram
         fromPeer:(NSString *)peer;
@end



#endif
