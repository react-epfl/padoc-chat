//
//  MHCBSProtocol.h
//  Padoc
//
//  Created by quarta on 23/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef Padoc_MHCBSProtocol_h
#define Padoc_MHCBSProtocol_h


#import "MHRoutingProtocol.h"
#import "MHFloodingProtocol.h"


@interface MHCBSProtocol : MHFloodingProtocol

#pragma mark - Initialization
- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName;

@end



#endif
