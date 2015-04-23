//
//  ViewController.m
//  MultihopChat
//
//  Created by Sven Reber on 27/03/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "ViewController.h"
#import "Message.h"

#define GLOBAL @"global"

@interface ViewController () <MHMulticastSocketDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) MHMulticastSocket *socket;

@end

@implementation ViewController

- (void)viewDidLoad {
    NSLog(@"HELLO");
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socket = [[MHMulticastSocket alloc] initWithServiceType:@"chat"];
    self.socket.delegate = self;
    [self.socket joinGroup:GLOBAL];
    [self.socket joinGroup:[self.socket getOwnPeer]];
    
    //[self.tableView setDelegate:self];
    //[self.tableView setDataSource:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
          failedToConnect:(NSError *)error
{
    
}


- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
         didReceivePacket:(MHPacket *)packet {
    
    Message* msg = [NSKeyedUnarchiver unarchiveObjectWithData:packet.data];
    
    if ([msg.type isEqualToString:@"discovery"]) {
        
        Message* sentMsg = [[Message alloc] initWithType:@"discovery-reply"
                                            withContent:[UIDevice currentDevice].name];
        
        MHPacket* sentPacket = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                               withDestinations:[[NSArray alloc] initWithObjects:packet.source, nil]
                                                       withData:[NSKeyedArchiver archivedDataWithRootObject:sentMsg]];
        
        NSError *error;
        
        [self.socket sendPacket:sentPacket error:&error];
        
    } else if ([msg.type isEqualToString:@"discovery-reply"]) {
        
        NSString* displayName = (NSString*)msg.content;
        
        NSLog(displayName);
        
    }
}

- (IBAction)send:(id)sender {
    
    Message* msg = [[Message alloc] initWithType:@"discovery"
                                     withContent:nil];
    
    MHPacket* packet = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                       withDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                                               withData:[NSKeyedArchiver archivedDataWithRootObject:msg]];
    
    NSError *error;
    
    [self.socket sendPacket:packet error:&error];
    
}

@end
