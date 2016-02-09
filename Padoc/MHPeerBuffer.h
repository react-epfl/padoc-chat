//
//  MHPeerBuffer.h
//  Padoc
//
//  Created by quarta on 13/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHPeerBuffer_h
#define Padoc_MHPeerBuffer_h

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MHDatagram.h"

#import "MHConfig.h"

#define MHPEERBUFFER_BUFFER_SIZE 1000

#define MHPEERBUFFER_DECREASE_AMOUNT 50
#define MHPEERBUFFER_LOWEST_DELAY 10

@protocol MHPeerBufferDelegate;

@interface MHPeerBuffer : NSObject

@property(nonatomic, weak) id<MHPeerBufferDelegate> delegate;

#pragma mark - Initialization
- (instancetype)initWithMCSession:(MCSession *)session;


- (void)pushDatagram:(MHDatagram *)datagram;


- (void)setDelayTo:(NSInteger)delay;

- (void)setConnected;
- (void)setDisconnected;

- (void)didReceiveDatagramChunk:(MHDatagram *)chunk;

@end



@protocol MHPeerBufferDelegate <NSObject>

@required
- (void)mhPeerBuffer:(MHPeerBuffer *)mhPeerBuffer
  didReceiveDatagram:(MHDatagram *)datagram;

@end



#endif
