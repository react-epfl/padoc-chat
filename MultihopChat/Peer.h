//
//  Peer.h
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#ifndef MultihopChat_Peer_h
#define MultihopChat_Peer_h
#import <Foundation/Foundation.h>

@interface Peer : NSObject<NSCoding>

@property (nonatomic, readonly, strong) NSString *peerId;
@property (nonatomic, readonly, strong) NSString *displayName;


- (instancetype)initWithPeerId:(NSString *)peerId
               withDisplayName:(NSString *)displayName;


@end


#endif
