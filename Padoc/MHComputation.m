//
//  MHComputation.m
//  Padoc
//
//  Created by quarta on 12/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHComputation.h"



@interface MHComputation ()

@end

@implementation MHComputation

+ (NSString *)makeUniqueStringFromSource:(NSString *)source
{
    // Generate string based on datetime
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyMMddHHmmss"];
    
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Generate random value
    int randomValue = arc4random() % 100000;
    
    
    // Generate final string of the form: [date][source][random value]
    return [NSString stringWithFormat:@"%@%@%d",dateString, source, randomValue];
}

# pragma mark - Math helper methods
+ (double)sign:(double)value
{
    if (value >= 0)
    {
        return 1.0;
    }
    
    return -1.0;
}

+ (double)toRad:(double)deg
{
    return deg * M_PI / 180.0;
}

#pragma mark - Data helper methods
+ (NSData*)emptyData
{
    return [@"" dataUsingEncoding:NSUTF8StringEncoding];
}

@end