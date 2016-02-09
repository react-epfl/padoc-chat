//
//  Peer.h
//  PadocChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#ifndef PadocChat_Peer_h
#define PadocChat_Peer_h
#import <Foundation/Foundation.h>

#import "ChatMessage.h"

@interface Peer : NSObject

@property (nonatomic, readonly, strong) NSString *peerId;
@property (nonatomic, readonly, strong) NSString *displayName;
@property (nonatomic, readonly, strong) NSMutableArray *chatMessages;

@property (nonatomic, readwrite) int unreadMessages;


- (instancetype)initWithPeerId:(NSString *)peerId
               withDisplayName:(NSString *)displayName;

- (void) setChatMessages:(NSMutableArray *)chatMessages;
- (void) addMessage:(ChatMessage *)message;


@end


#endif
