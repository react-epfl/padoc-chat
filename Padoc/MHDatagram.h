//
//  MHDatagram.h
//  Padoc
//
//  Created by quarta on 13/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHDatagram_h
#define Padoc_MHDatagram_h


#import <Foundation/Foundation.h>
#import "MHComputation.h"


@interface MHDatagram : NSObject<NSCoding>

@property (nonatomic, strong) NSData *data;

@property (nonatomic, readonly, strong) NSMutableDictionary *info;

@property (nonatomic, strong) NSString *tag;
@property (nonatomic) int noChunk;
@property (nonatomic) int chunksNumber;

- (instancetype)initWithData:(NSData *)data;


- (NSData *)asNSData;


+ (MHDatagram *)fromNSData:(NSData *)nsData;
@end



#endif
