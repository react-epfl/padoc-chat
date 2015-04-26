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

@end


@implementation Peer

- (instancetype)initWithPeerId:(NSString *)peerId
                 withDisplayName:(NSString *)displayName
{
    self = [super init];
    if (self)
    {
        self.peerId = peerId;
        self.displayName = displayName;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.peerId = [decoder decodeObjectForKey:@"peerId"];
        self.displayName = [decoder decodeObjectForKey:@"displayName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.peerId forKey:@"peerId"];
    [encoder encodeObject:self.displayName forKey:@"displayName"];
}


- (void)dealloc
{
    self.peerId = nil;
    self.displayName = nil;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    } else {
        return [self.peerId isEqualToString:((Peer*)other).peerId];
    }
}


@end