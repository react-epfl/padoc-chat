//
//  ChatMessage.h
//  PadocChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#ifndef PadocChat_ChatMessage_h
#define PadocChat_ChatMessage_h
#import <Foundation/Foundation.h>


@interface ChatMessage : NSObject<NSCoding>

@property (nonatomic, readonly, strong) NSString *source;
@property (nonatomic, readonly, strong) NSDate *date;
@property (nonatomic, readonly, strong) NSString *content;


- (instancetype)initWithSource:(NSString *)source
                      withDate:(NSDate *)date
                   withContent:(NSString *) content;


@end


#endif