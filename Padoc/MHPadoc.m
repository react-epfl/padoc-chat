//
//  MHPadoc.m
//  Padoc
//
//  Created by quarta on 02/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHPadoc.h"


@interface MHPadoc () <MHControllerDelegate>

@property (nonatomic, strong) MHController *mhController;
@end

@implementation MHPadoc

#pragma mark - Life Cycle

- (instancetype)initWithServiceType:(NSString *)serviceType
{
    return [self initWithServiceType:serviceType
                         displayName:[UIDevice currentDevice].name
                 withRoutingProtocol:MHFloodingRoutingProtocol];
}


- (instancetype)initWithServiceType:(NSString *)serviceType
                withRoutingProtocol:(MHRoutingProtocols)protocol
{
    return [self initWithServiceType:serviceType
                         displayName:[UIDevice currentDevice].name
                 withRoutingProtocol:protocol];
}


- (instancetype)initWithServiceType:(NSString *)serviceType
                        displayName:(NSString *)displayName
                withRoutingProtocol:(MHRoutingProtocols)protocol
{
    self = [super init];
    if (self)
    {
        self.mhController = [[MHController alloc] initWithServiceType:serviceType
                                                          displayName:displayName
                                                  withRoutingProtocol:protocol];
        
        self.mhController.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    self.mhController  = nil;
}


#pragma mark - Communicate

- (void)disconnect
{
    [self.mhController disconnect];
}

- (void)joinGroup:(NSString *)groupName
{
    [self joinGroup:groupName maxHops:[MHConfig getSingleton].netPacketTTL];
}

- (void)joinGroup:(NSString *)groupName
          maxHops:(int)maxHops
{
    [self.mhController joinGroup:groupName maxHops:maxHops];
}

- (void)leaveGroup:(NSString *)groupName
{
    [self leaveGroup:groupName maxHops:[MHConfig getSingleton].netPacketTTL];
}

- (void)leaveGroup:(NSString *)groupName
           maxHops:(int)maxHops
{
    [self.mhController leaveGroup:groupName maxHops:maxHops];
}


- (void)multicastMessage:(NSData *)data
     toDestinations:(NSArray *)destinations
              error:(NSError **)error
{
    [self multicastMessage:data toDestinations:destinations maxHops:[MHConfig getSingleton].netPacketTTL error:error];
}

- (void)multicastMessage:(NSData *)data
     toDestinations:(NSArray *)destinations
            maxHops:(int)maxHops
              error:(NSError **)error
{
    MHMessage *message = [[MHMessage alloc] initWithData:data];
    
    [self.mhController sendMessage:message toDestinations:destinations maxHops:maxHops error:error];
}



- (NSString *)getOwnPeer
{
    return [self.mhController getOwnPeer];
}

- (int)hopsCountFromPeer:(NSString*)peer
{
    return [self.mhController hopsCountFromPeer:peer];
}



#pragma mark - Background Mode methods
- (void)applicationWillResignActive {
    [self.mhController applicationWillResignActive];
}

- (void)applicationDidBecomeActive{
    [self.mhController applicationDidBecomeActive];
}



# pragma mark - Termination method
- (void)applicationWillTerminate {
    [self disconnect];
}




#pragma mark - MHController Delegates

- (void)mhController:(MHController *)mhController
     failedToConnect:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mhPadoc:self failedToConnect:error];
    });
}

- (void)mhController:(MHController *)mhController
   didReceiveMessage:(MHMessage *)message
          fromGroups:(NSArray *)groups
       withTraceInfo:(NSArray *)traceInfo
{
    if (traceInfo != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate mhPadoc:self deliverMessage:message.data fromGroups:groups withTraceInfo:traceInfo];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate mhPadoc:self deliverMessage:message.data fromGroups:groups];
        });
    }
}



#pragma mark - Diagnostics info callbacks
- (void)mhController:(MHController *)mhController
       forwardPacket:(NSString *)info
         withMessage:(MHMessage *)message
          fromSource:(NSString *)peer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(mhPadoc:forwardPacket:withMessage:fromSource:)])
        {
            [self.delegate mhPadoc:self
                      forwardPacket:info
                        withMessage:message.data
                         fromSource:peer];
        }
    });
}

- (void)mhController:(MHController *)mhController
  neighbourConnected:(NSString *)info
                peer:(NSString *)peer
         displayName:(NSString *)displayName

{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(mhPadoc:neighbourConnected:peer:displayName:)])
        {
            [self.delegate mhPadoc:self neighbourConnected:info peer:peer displayName:displayName];
        }
    });
}

- (void)mhController:(MHController *)mhController
neighbourDisconnected:(NSString *)info
                peer:(NSString *)peer

{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(mhPadoc:neighbourDisconnected:peer:)])
        {
            [self.delegate mhPadoc:self neighbourDisconnected:info peer:peer];
        }
    });
}

- (void)mhController:(MHController *)mhController
         joinedGroup:(NSString *)info
                peer:(NSString *)peer
         displayName:(NSString *)displayName
               group:(NSString *)group
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(mhPadoc:joinedGroup:peer:displayName:group:)])
        {
            [self.delegate mhPadoc:self
                        joinedGroup:info
                               peer:peer
                        displayName:displayName
                              group:group];
        }
    });
}
@end
