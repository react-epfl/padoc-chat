//
//  MCPeer.m
//  Padoc
//
//  Created by quarta on 16/03/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "MHPeer.h"


@interface MHPeer () <MCSessionDelegate, MHPeerBufferDelegate>

// Public Properties
@property (nonatomic, readwrite, strong) NSString *displayName;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCPeerID *mcPeerID;
@property (nonatomic, strong) NSString *mhPeerID;

@property (nonatomic, strong) MHPeerBuffer *peerBuffer;

// Receiving side congestion control
@property (nonatomic) NSTimeInterval lastReceivedPacketTime;
@property (nonatomic) int sendingRateCheckFailures;


// Heartbeat congestion control
@property (nonatomic) NSInteger heartbeatSendingDelay;
@property (nonatomic) NSInteger heartbeatReceivingDelay;

@property (nonatomic) NSTimeInterval lastHeartbeatReceivedPacketTime;
@property (nonatomic) int sendingRateHeartbeatCheckFailures;
@property (nonatomic) NSTimeInterval lastHeartbeatSentPacketTime;


@property (nonatomic) BOOL connected;

@property (nonatomic) BOOL heartbeatStarted;
@property (nonatomic) int nbHeartbeatFails;
@property (nonatomic) BOOL HeartbeatSender;

@property (copy) void (^processSendingHeartbeat)(void);
@property (copy) void (^processReceivingHeartbeat)(void);

@end


@implementation MHPeer


#pragma mark - Life Cycle

- (instancetype)initWithDisplayName:(NSString *)displayName
                    withOwnMCPeerID:(MCPeerID *)ownMCPeerID
                    withOwnMHPeerID:(NSString *)ownMHPeerID
                       withMCPeerID:(MCPeerID *)mcPeerID
                       withMHPeerID:(NSString *)mhPeerID
{
    self = [super init];
    if (self)
    {
        self.nbHeartbeatFails = 0;
        self.heartbeatStarted = NO;
        self.heartbeatSendingDelay = [MHConfig getSingleton].linkHeartbeatSendDelay;
        self.heartbeatReceivingDelay = [MHConfig getSingleton].linkHeartbeatSendDelay;
        
        self.displayName = displayName;
        self.mcPeerID = mcPeerID;
        self.mhPeerID = mhPeerID;
        
        if (![ownMCPeerID isEqual:mcPeerID]) // if it is not the owner mhPeer we create a session
        {
            self.session = [[MCSession alloc] initWithPeer:ownMCPeerID
                                          securityIdentity:nil
                                      encryptionPreference:MCEncryptionRequired];
            self.session.delegate = self;
            
            
            self.peerBuffer = [[MHPeerBuffer alloc] initWithMCSession:self.session];
            self.peerBuffer.delegate = self;
            
            self.lastReceivedPacketTime = [[NSDate date] timeIntervalSince1970];
            self.sendingRateCheckFailures = 0;
            
            // Heartbeat mechanism
            MHPeer * __weak weakSelf = self;
            
            [self setFctProcessSendingHeartbeat:weakSelf];
            [self setFctProcessReceivingHeartbeat:weakSelf];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MHPEER_STARTHEARTBEAT_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if(weakSelf)
                {
                    // No connection callback has yet been executed (MC bug)
                    // Try determining connection by heartbeat
                    [weakSelf startHeartbeat:weakSelf];
                }
            });
        }
    }
    return self;
}


- (void)dealloc
{
    [self disconnect];
    self.session = nil;
    self.mcPeerID = nil;
    self.peerBuffer = nil;
    self.displayName = nil;
    self.mhPeerID = nil;

    self.processReceivingHeartbeat = nil;
    self.processSendingHeartbeat = nil;

}


- (void)setFctProcessSendingHeartbeat:(MHPeer * __weak)weakSelf
{
    // Sender side
    self.processSendingHeartbeat = ^{
        if(weakSelf)
        {
            if (weakSelf.connected)
            {
                NSTimeInterval newSentTime = [[NSDate date] timeIntervalSince1970];
                
                NSError *error;
                MHDatagram *datagram = [[MHDatagram alloc] initWithData:[MHComputation emptyData]];
                [datagram.info setObject:@"" forKey:MHPEER_HEARTBEAT_MSG];
                // Delay in ms
                [datagram.info setObject:[NSNumber numberWithInteger:1000*(newSentTime - weakSelf.lastHeartbeatSentPacketTime)] forKey:@"delay"];
                

                
                [weakSelf.session sendData:[datagram asNSData]
                                   toPeers:weakSelf.session.connectedPeers
                                  withMode:MCSessionSendDataReliable
                                     error:&error];
                
                
                weakSelf.lastHeartbeatSentPacketTime = newSentTime;
                
                // Decrease sending delay
                weakSelf.heartbeatSendingDelay -= MHPEER_HEARTBEAT_DECREASE_AMOUNT;
                if (weakSelf.heartbeatSendingDelay < [MHConfig getSingleton].linkHeartbeatSendDelay)
                {
                    weakSelf.heartbeatSendingDelay = [MHConfig getSingleton].linkHeartbeatSendDelay;
                }
                
                // Dispatch after y seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.heartbeatSendingDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processSendingHeartbeat);
            }
        }
    };
}

- (void)setFctProcessReceivingHeartbeat:(MHPeer * __weak)weakSelf
{
    // Sender side
    self.processReceivingHeartbeat = ^{
        if(weakSelf)
        {
            weakSelf.nbHeartbeatFails++;
            
            // The heartbeat fails for x times, then disconnect
            if (weakSelf.nbHeartbeatFails > [MHConfig getSingleton].linkMaxHeartbeatFails)
            {
                [weakSelf setConnectionDisabled:weakSelf withReason:@"Heartbeat failed"];
            }
            else
            {
                // Dispatch after y seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.heartbeatReceivingDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processReceivingHeartbeat);
            }
        }
    };
}


- (void)startHeartbeat:(MHPeer * __weak)weakSelf
{
    if (!weakSelf.heartbeatStarted)
    {
        weakSelf.heartbeatStarted = YES;
        
        weakSelf.lastHeartbeatReceivedPacketTime = [[NSDate date] timeIntervalSince1970];
        weakSelf.sendingRateHeartbeatCheckFailures = 0;
        weakSelf.lastHeartbeatSentPacketTime = [[NSDate date] timeIntervalSince1970];
        
        // Dispatch after y seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.heartbeatSendingDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processSendingHeartbeat);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.heartbeatReceivingDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.processReceivingHeartbeat);
    }
}

- (void)disconnect
{
    self.connected = NO;
    // Will clean up the session properly
    [self.session disconnect];
}


- (void)sendDatagram:(MHDatagram *)datagram
               error:(NSError **)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.peerBuffer pushDatagram:datagram];
    });
}


#pragma mark - Session Delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if(state == MCSessionStateNotConnected) {
        // We cannot rely on this callback!! In certain environments,
        // it is called continously even if the peers are actually conected
    }
    else if(state == MCSessionStateConnected)
    {
        [self startHeartbeat:self];
        [self setConnectionEnabled];
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Reset the heartbeat fail counter
        self.nbHeartbeatFails = 0;
    });
    
    MHDatagram *datagram = [MHDatagram fromNSData:data];

    if ([datagram.info objectForKey:MHPEER_HEARTBEAT_MSG] != nil)
    {
        [self controlHeartbeatCongestionWithSendingDelay:[[datagram.info objectForKey:@"delay"] integerValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setConnectionEnabled];
        });
    }
    else if ([datagram.info objectForKey:MHPEER_CONGESTION_CONTROL_MSG] != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger rcvDelay = [[datagram.info objectForKey:@"delay"] integerValue];

            [self.peerBuffer setDelayTo:rcvDelay];
        });
    }
    else if ([datagram.info objectForKey:MHPEER_HEARTBEAT_CONGESTION_CONTROL_MSG] != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger rcvDelay = [[datagram.info objectForKey:@"delay"] integerValue];
            
            self.heartbeatSendingDelay = rcvDelay + MHPEER_HEARTBEAT_DECREASE_AMOUNT;
            
            if (self.heartbeatSendingDelay < [MHConfig getSingleton].linkHeartbeatSendDelay)
            {
                self.heartbeatSendingDelay = [MHConfig getSingleton].linkHeartbeatSendDelay;
            }
        });
    }
    else
    {
        [self controlCongestionWithSendingDelay:[[datagram.info objectForKey:@"delay"] integerValue]];
        
        [self.peerBuffer didReceiveDatagramChunk:datagram];
    }
}

- (void)controlCongestionWithSendingDelay:(NSInteger)sendingDelay
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval newReceivingTime = [[NSDate date] timeIntervalSince1970];
        NSInteger receivingDelay = 1000*(newReceivingTime - self.lastReceivedPacketTime);

        if (receivingDelay > sendingDelay + MHPEER_RECEIVING_DELAY_PRECISION)
        {
            self.sendingRateCheckFailures++;
            
            if (self.sendingRateCheckFailures >= 2)
            {
                MHDatagram *congestionControlDatagram = [[MHDatagram alloc] initWithData:nil];
                [congestionControlDatagram.info setObject:@"" forKey:MHPEER_CONGESTION_CONTROL_MSG];
                [congestionControlDatagram.info setObject:[NSNumber numberWithInteger:receivingDelay] forKey:@"delay"];
                
                NSError *error;
                [self.session sendData:[congestionControlDatagram asNSData]
                               toPeers:self.session.connectedPeers
                              withMode:MCSessionSendDataUnreliable
                                 error:&error];
                
                self.sendingRateCheckFailures = 0;
            }
        }
        else
        {
            self.sendingRateCheckFailures = 0;
        }

        self.lastReceivedPacketTime = newReceivingTime;
    });
}

- (void)controlHeartbeatCongestionWithSendingDelay:(NSInteger)sendingDelay
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval newReceivingTime = [[NSDate date] timeIntervalSince1970];
        NSInteger receivingDelay = 1000*(newReceivingTime - self.lastHeartbeatReceivedPacketTime);
        
        if (receivingDelay > sendingDelay + MHPEER_RECEIVING_DELAY_PRECISION)
        {
            self.sendingRateHeartbeatCheckFailures++;
            
            if (self.sendingRateHeartbeatCheckFailures >= 2)
            {
                MHDatagram *congestionControlDatagram = [[MHDatagram alloc] initWithData:nil];
                [congestionControlDatagram.info setObject:@"" forKey:MHPEER_HEARTBEAT_CONGESTION_CONTROL_MSG];
                [congestionControlDatagram.info setObject:[NSNumber numberWithInteger:receivingDelay] forKey:@"delay"];
                
                NSError *error;
                [self.session sendData:[congestionControlDatagram asNSData]
                               toPeers:self.session.connectedPeers
                              withMode:MCSessionSendDataUnreliable
                                 error:&error];
                
                // If we receive messages more slowly than the sending rate,
                // we want to check at our receiving rate
                self.heartbeatReceivingDelay = receivingDelay;
                
                self.sendingRateHeartbeatCheckFailures = 0;
            }
        }
        else
        {
            // If we receive messages more quickly than the sending rate,
            // we want to check at the sending rate, which is decreasing
            self.heartbeatReceivingDelay = sendingDelay;
            
            self.sendingRateHeartbeatCheckFailures = 0;
        }
        
        self.lastHeartbeatReceivedPacketTime = newReceivingTime;
    });
}


- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    // Unsupported: Nothing to do
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // Unsupported: Nothing to do
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    // Unsupported: Nothing to do
}

// Required because of an apple bug
- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}


- (void)mhPeerBuffer:(MHPeerBuffer *)mhPeerBuffer didReceiveDatagram:(MHDatagram *)datagram
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate mhPeer:self didReceiveDatagram:datagram];
    });
}


#pragma mark - Connection helper methods
- (void)setConnectionEnabled
{
    if (!self.connected)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connected = YES;
            [self.peerBuffer setConnected];
            [self.delegate mhPeer:self hasConnected:@"Connected"];
        });
    }
}

- (void)setConnectionDisabled:(MHPeer * __weak)weakSelf withReason:(NSString *)reason
{
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.connected = NO;
        [self.peerBuffer setDisconnected];
        [weakSelf.delegate mhPeer:weakSelf hasDisconnected:reason];
    });
}


# pragma mark - Static methods

+ (MHPeer *)getOwnMHPeerWithDisplayName:(NSString *)displayName
{
    NSString *mhPeerID = [[NSUserDefaults standardUserDefaults] valueForKey:@"PadocID"];
    
    if(mhPeerID == nil)
    {
        // Generation of a new PeerID
        mhPeerID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setValue:mhPeerID forKey:@"PadocID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    MCPeerID *mcPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    return [[MHPeer alloc] initWithDisplayName:displayName
                               withOwnMCPeerID:mcPeerID
                               withOwnMHPeerID:@""
                                  withMCPeerID:mcPeerID
                                  withMHPeerID:mhPeerID];
}


@end
