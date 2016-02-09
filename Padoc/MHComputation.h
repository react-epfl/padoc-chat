//
//  MHComputation.h
//  Padoc
//
//  Created by quarta on 12/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHComputation_h
#define Padoc_MHComputation_h

#import <Foundation/Foundation.h>


@interface MHComputation : NSObject

+ (NSString *)makeUniqueStringFromSource:(NSString *)source;

#pragma mark - Math helper methods
+ (double)sign:(double)value;

+ (double)toRad:(double)deg;


#pragma mark - Data helper methods
+ (NSData*)emptyData;

@end


#endif
