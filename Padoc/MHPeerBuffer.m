//
//  MHPeerBuffer.m
//  Padoc
//
//  Created by quarta on 13/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHPeerBuffer.h"



@interface MHPeerBuffer()

// Public properties

@property (nonatomic, strong) NSMutableArray *datagrams;
@property (nonatomic, strong) MCSession *session;

@property (nonatomic) BOOL connected;
@property (nonatomic) NSInteger releaseDelay;
@property (nonatomic) NSInteger lowestReleaseDelay;

@property (nonatomic, strong) NSMutableDictionary *chunks;

@property (nonatomic) NSTimeInterval lastSentPacketTime;

@property (copy) void (^releaseDatagrams)(void);

@end

@implementation MHPeerBuffer

#pragma mark - Life Cycle

- (instancetype)initWithMCSession:(MCSession *)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.connected = NO;
        self.releaseDelay = [MHConfig getSingleton].linkDatagramSendDelay;
        self.lowestReleaseDelay = MHPEERBUFFER_LOWEST_DELAY;

        self.datagrams = [[NSMutableArray alloc] init];

        self.chunks = [[NSMutableDictionary alloc] init];
        
        MHPeerBuffer * __weak weakSelf = self;
        
        self.lastSentPacketTime = [[NSDate date] timeIntervalSince1970];
        
        
        self.releaseDatagrams = ^{
            if (weakSelf)
            {
                if (weakSelf.connected)
                {
                    MHDatagram * datagram = [weakSelf popDatagram];

                    if (datagram != nil)
                    {
                        
                        NSTimeInterval newSentTime = [[NSDate date] timeIntervalSince1970];
                        
                        // Delay in ms
                        [datagram.info setObject:[NSNumber numberWithInteger:1000*(newSentTime - weakSelf.lastSentPacketTime)] forKey:@"delay"];
                        
                        NSError *error;
                        [weakSelf.session sendData:[datagram asNSData]
                                           toPeers:weakSelf.session.connectedPeers
                                          withMode:MCSessionSendDataReliable
                                             error:&error];
                        
                        weakSelf.lastSentPacketTime = newSentTime;
                        [weakSelf decreaseDelay:weakSelf];
                    }
                    else
                    {
                        [weakSelf increaseDelay:weakSelf];
                    }
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(weakSelf.releaseDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), weakSelf.releaseDatagrams);
            }
        };
        
        // Check every x seconds for buffered messages
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.releaseDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), self.releaseDatagrams);
    }
    return self;
}

- (void)dealloc
{
    [self.datagrams removeAllObjects];
    self.datagrams = nil;
    
    [self.chunks removeAllObjects];
    self.chunks = nil;
    
    self.releaseDatagrams = nil;
    
    self.session = nil;
}

- (void)decreaseDelay:(MHPeerBuffer * __weak)weakSelf
{
    weakSelf.releaseDelay -= MHPEERBUFFER_DECREASE_AMOUNT;
    
    if (weakSelf.releaseDelay < self.lowestReleaseDelay)
    {
        weakSelf.releaseDelay = self.lowestReleaseDelay;
    }
}

- (void)increaseDelay:(MHPeerBuffer * __weak)weakSelf
{
    weakSelf.releaseDelay += MHPEERBUFFER_DECREASE_AMOUNT;
    
    if (weakSelf.releaseDelay > self.lowestReleaseDelay)
    {
        weakSelf.releaseDelay = self.lowestReleaseDelay;
    }
}

- (void)setDelayTo:(NSInteger)delay
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.releaseDelay = delay + MHPEERBUFFER_DECREASE_AMOUNT;
        
        if (self.releaseDelay < self.lowestReleaseDelay)
        {
            self.releaseDelay = self.lowestReleaseDelay;
        }
    });
}


- (void)setConnected
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connected = YES;
    });
}

- (void)setDisconnected
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connected = NO;
    });
}

- (void)pushDatagram:(MHDatagram *)datagram
{
    // If buffer size is reached, messages are lost
    dispatch_async(dispatch_get_main_queue(), ^{
        // We have to divide datagrams into chunks
        // in order to better handle the sending rate
        
        // Calculating number of chunks
        int nbChunks = ceil(((double)datagram.data.length / [MHConfig getSingleton].linkMaxDatagramSize));
        
        // Creating a unique tag for every chunk corresponding to
        // this datagram
        NSString *tag = [MHComputation makeUniqueStringFromSource:[NSString stringWithFormat:@"%d", arc4random_uniform(1000)]];
        
        for (int i = 0; i < nbChunks; i++)
        {
            NSInteger length = [MHConfig getSingleton].linkMaxDatagramSize;
            
            if (i == nbChunks - 1) // Last chunk
            {
                length = datagram.data.length - (i * [MHConfig getSingleton].linkMaxDatagramSize);
            }
            
            MHDatagram *chunk = [[MHDatagram alloc] initWithData:[datagram.data subdataWithRange:NSMakeRange(i * [MHConfig getSingleton].linkMaxDatagramSize, length)]];
            chunk.tag = tag;
            chunk.noChunk = i;
            chunk.chunksNumber = nbChunks;
            
            // Putitng chunk into sending buffer
            if (self.datagrams.count < MHPEERBUFFER_BUFFER_SIZE)
            {
                [self.datagrams addObject:chunk];
            }
        }
    });
}

- (MHDatagram *)popDatagram
{
    // Pop first item and return
    if (self.datagrams.count > 0)
    {
        MHDatagram *datagram = [self.datagrams objectAtIndex:0];
        [self.datagrams removeObjectAtIndex:0];
        
        return datagram;
    }
    
    return nil;
}


- (void)didReceiveDatagramChunk:(MHDatagram *)chunk
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *chunksList = [self.chunks objectForKey:chunk.tag];
        
        if (chunksList == nil)
        {
            chunksList = [[NSMutableArray alloc] init];
            [self.chunks setObject:chunksList forKey:chunk.tag];
        }
        
        // Potentially unordered
        [chunksList addObject:chunk];
        
        
        // Generate complete chunk if all chunks received
        if (chunksList.count == chunk.chunksNumber)
        {
            // We sort the chunk list
            [chunksList sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
                
                MHDatagram *d1 = (MHDatagram*)obj1;
                MHDatagram *d2 = (MHDatagram*)obj2;
                if (d1.noChunk > d2.noChunk) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                
                if (d1.noChunk < d2.noChunk) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
            
            // We create the final complete datagram
            NSMutableData *completeData = [NSMutableData data];
            MHDatagram *finalDatagram = [[MHDatagram alloc] initWithData:completeData];
            
            for (int i = 0; i < chunksList.count; i++)
            {
                MHDatagram *partialChunk = (MHDatagram *)[chunksList objectAtIndex:i];
                [completeData appendData:partialChunk.data];
            }
            
            // We delete the temporary stored chunks
            [self.chunks removeObjectForKey:chunk.tag];
            
            // Notify upper layers
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate mhPeerBuffer:self didReceiveDatagram:finalDatagram];
            });
        }
    });
}

@end