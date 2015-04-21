//
//  DiscoveryReply.h
//  MultihopChat
//
//  Created by Sven Reber on 21/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#ifndef MultihopChat_DiscoveryReply_h
#define MultihopChat_DiscoveryReply_h

#import <Foundation/Foundation.h>


@interface DiscoveryReply : NSObject<NSCoding>

@property (nonatomic, readonly, strong) NSString *displayName;

@property (nonatomic, readonly, strong) NSMutableDictionary *info;


- (instancetype)initWithSource:(NSString *)source
              withDestinations:(NSArray *)destinations
                      withData:(NSData *)data;

- (NSData *)asNSData;


+ (MHPacket *)fromNSData:(NSData *)nsData;

+ (NSString *)makeUniqueStringFromPeer:(NSString *)peer;

@end

#endif
