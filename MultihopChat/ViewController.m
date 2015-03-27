//
//  ViewController.m
//  MultihopChat
//
//  Created by Sven Reber on 27/03/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <MHMulticastSocketDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MHMulticastSocket *socket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socket = [[MHMulticastSocket alloc] initWithServiceType:@"MultihopChat"];
    [self.socket joinGroup:@"global"];
    [self.socket joinGroup:[self.socket getOwnPeer]];
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
         didReceivePacket:(MHPacket *)packet
{
    NSString *msg = [[NSString alloc] initWithData:packet.data encoding:NSUTF8StringEncoding];
    if ([msg isEqualToString:@"discovery"]) {
        MHPacket* sentPacket = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                               withDestinations:[[NSArray alloc] initWithObjects:packet.source, nil]
                                                       withData:[@"discovery-reply" dataUsingEncoding:NSUTF8StringEncoding]];
        NSError *error;
        [self.socket sendPacket:sentPacket error:&error];
    }
}

@end
