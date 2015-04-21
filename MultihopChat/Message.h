//
//  Message.h
//  MultihopChat
//
//  Created by Sven Reber on 21/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#ifndef MultihopChat_Message_h
#define MultihopChat_Message_h
#import <Foundation/Foundation.h>


@interface Message : NSObject<NSCoding>

@property (nonatomic, readonly, strong) NSString *type;
@property (nonatomic, readonly, strong) NSObject *content;


- (instancetype)initWithType:(NSString *)type
                 withContent:(NSObject *)content;


@end


#endif
