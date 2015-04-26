//
//  MasterViewController.m
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import "Message.h"
#import "Peer.h"

#define GLOBAL @"global"


@interface MasterViewController () <MHMulticastSocketDelegate>

@property NSMutableArray *objects;
@property (strong, nonatomic) MHMulticastSocket *socket;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    self.objects = [NSMutableArray array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // No left button
    self.navigationItem.leftBarButtonItem = nil;
    
    // Right button is used to discover peers
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(discoverPeers:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // Set up the socket and the groups
    self.socket = [[MHMulticastSocket alloc] initWithServiceType:@"chat"];
    self.socket.delegate = self;
    [self.socket joinGroup:GLOBAL];
    [self.socket joinGroup:[self.socket getOwnPeer]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)discoverPeers:(id)sender {
    [self.objects removeAllObjects];
    
    Message* msg = [[Message alloc] initWithType:@"discovery"
                                     withContent:[UIDevice currentDevice].name];
    
    MHPacket* packet = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                       withDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                                               withData:[NSKeyedArchiver archivedDataWithRootObject:msg]];
    
    NSError *error;
    
    [self.socket sendPacket:packet error:&error];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Peer *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        [controller setSocket:self.socket];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Peer *object = self.objects[indexPath.row];
    cell.textLabel.text = [object displayName];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - Methods of MHMultiCast

- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
          failedToConnect:(NSError *)error {
    
}


- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
         didReceivePacket:(MHPacket *)packet {
    
    Message* msg = [NSKeyedUnarchiver unarchiveObjectWithData:packet.data];
    
    if ([msg.type isEqualToString:@"discovery"]) {
        
        // Reply to the discovery request
        
        Message* sentMsg = [[Message alloc] initWithType:@"discovery-reply"
                                             withContent:[UIDevice currentDevice].name];
        
        MHPacket* sentPacket = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                               withDestinations:[[NSArray alloc] initWithObjects:packet.source, nil]
                                                       withData:[NSKeyedArchiver archivedDataWithRootObject:sentMsg]];
        
        NSError *error;
        
        [self.socket sendPacket:sentPacket error:&error];
        
        // Add the peer that initiated the discovery to the list of peers if not already present
        
        NSString* displayName = (NSString*)msg.content;
        
        Peer *peer = [[Peer alloc] initWithPeerId:packet.source withDisplayName:displayName];
        
        if (![self.objects containsObject:peer]) {
            [self.objects addObject:peer];
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"discovery-reply"]) {
        
        NSString* displayName = (NSString*)msg.content;
        
        Peer *peer = [[Peer alloc] initWithPeerId:packet.source withDisplayName:displayName];
        
        if (![self.objects containsObject:peer]) {
            [self.objects addObject:peer];
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"chat-text"]) {
        
        [self.detailViewController addMessage:(NSString *)msg.content];
        
    }
}

@end
