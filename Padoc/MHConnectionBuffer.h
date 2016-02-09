//
//  MHConnectionBuffer.h
//  Padoc
//
//  Created by quarta on 26/03/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHConnectionBuffer_h
#define Padoc_MHConnectionBuffer_h

#import <Foundation/Foundation.h>
#import "MHMultipeerWrapper.h"
#import "MHDatagram.h"

#import "MHConfig.h"

#define MHCONNECTIONBUFFER_BUFFER_SIZE 1000


typedef enum MHConnectionBufferState : NSUInteger
{
    MHConnectionBufferConnected,
    MHConnectionBufferBroken
} MHConnectionBufferState;


@interface MHConnectionBuffer : NSObject

#pragma mark - Properties
@property (nonatomic, readonly, strong) NSString *peerID;
@property (nonatomic, readonly) MHConnectionBufferState status;


#pragma mark - Initialization
- (instancetype)initWithPeerID:(NSString *)peerID
          withMultipeerWrapper:(MHMultipeerWrapper *)mcWrapper;


#pragma mark - Properties
- (void)setConnectionStatus:(MHConnectionBufferState)status;

- (void)pushDatagram:(MHDatagram *)datagram;


@end

#endif
