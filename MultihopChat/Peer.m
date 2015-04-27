//
//  Peer.m
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "Peer.h"

@interface Peer ()

@property (nonatomic, readwrite, strong) NSString *peerId;
@property (nonatomic, readwrite, strong) NSString *displayName;
@property (nonatomic, readwrite, strong) NSMutableArray *chatMessages;

@end


@implementation Peer

- (instancetype)initWithPeerId:(NSString *)peerId
               withDisplayName:(NSString *)displayName {
    self = [super init];
    if (self) {
        self.peerId = peerId;
        self.displayName = displayName;
        self.chatMessages = [NSMutableArray array];
    }
    return self;
}

- (void)addMessage:(ChatMessage *)message {
    [self.chatMessages addObject:message];
}

- (void)dealloc {
    self.peerId = nil;
    self.displayName = nil;
    self.chatMessages = nil;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    } else {
        return [self.peerId isEqualToString:((Peer*)other).peerId];
    }
}


@end