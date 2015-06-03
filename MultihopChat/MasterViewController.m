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
#import "ChatMessage.h"

#define GLOBAL @"global"


@interface MasterViewController () <MHMulticastSocketDelegate>

@property NSMutableArray *objects;
@property NSMutableDictionary *peersMessages;
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
    
    // For background mode
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setSocket:self.socket];
    
    // Join the groups
    [self.socket joinGroup:GLOBAL];
    [self.socket joinGroup:[self.socket getOwnPeer]];
    
    // Initialize the dictionary of messages
    self.peersMessages = [NSMutableDictionary dictionary];
    
    // Add the global chat room
    [self.objects addObject:[[Peer alloc] initWithPeerId:GLOBAL withDisplayName:@"Global room"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView:) name:@"MasterNotif" object:nil];
}

- (void)reloadTableView:(id)sender {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)discoverPeers:(id)sender {
    // Remove all objects but the first one (global)
    while ([self.objects count] > 1) {
        [self.objects removeLastObject];
    }
    [self.tableView reloadData];
    
    Message* msg = [[Message alloc] initWithType:@"discovery"
                                     withContent:[UIDevice currentDevice].name];
    
    NSError *error;
    
    [self.socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
              toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                       error:&error];
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

    Peer *peer = self.objects[indexPath.row];
    
    int hopsCount = [self.socket hopsCountFromPeer:peer.peerId];
    NSString *hopsCountText = hopsCount == 1 ? @"hop" : @"hops";
    NSString *hopsText = @"";
    if ([peer.peerId isEqualToString:GLOBAL]) {
        hopsText =  [NSString stringWithFormat:@" [%d %@]", hopsCount, hopsCountText];
    }
    
    int unreadMessages = [peer unreadMessages];
    NSString *unreadText = unreadMessages > 0 ? [NSString stringWithFormat:@" (%d unread)", unreadMessages] : @"";
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", [peer displayName], hopsText, unreadText];
    
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

- (void)mhSocket:(MHSocket *)mhSocket
          failedToConnect:(NSError *)error {
    
}


- (void)mhSocket:(MHSocket *)mhSocket
didReceiveMessage:(NSData *)data
        fromPeer:(NSString *)peer
   withTraceInfo:(NSArray *)traceInfo {
    
    Message* msg = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if ([msg.type isEqualToString:@"discovery"]) {
        
        // Reply to the discovery request
        
        Message* sentMsg = [[Message alloc] initWithType:@"discovery-reply"
                                             withContent:[UIDevice currentDevice].name];
        
        NSError *error;
        
        [self.socket sendMessage:[NSKeyedArchiver archivedDataWithRootObject:sentMsg]
                  toDestinations:[[NSArray alloc] initWithObjects:peer, nil]
                           error:&error];
        
        // Add the peer that initiated the discovery to the list of peers if not already present
        
        NSString *displayName = (NSString*)msg.content;
        
        Peer *peerObject = [[Peer alloc] initWithPeerId:peer withDisplayName:displayName];
        
        if (![self.objects containsObject:peerObject]) {
            [self.objects addObject:peerObject];
            
            NSMutableArray *peerMessages = [self.peersMessages objectForKey:peer];
            if (peerMessages) {
                [peerObject setChatMessages:peerMessages];
            } else {
                [self.peersMessages setValue:peerObject.chatMessages forKey:peerObject.peerId];
            }
            
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"discovery-reply"]) {
        
        NSString *displayName = (NSString*)msg.content;
        
        Peer *peerObject = [[Peer alloc] initWithPeerId:peer withDisplayName:displayName];
        
        if (![self.objects containsObject:peerObject]) {
            [self.objects addObject:peerObject];
            
            NSMutableArray *peerMessages = [self.peersMessages objectForKey:peer];
            if (peerMessages) {
                [peerObject setChatMessages:peerMessages];
            } else {
                [self.peersMessages setValue:peerObject.chatMessages forKey:peerObject.peerId];
            }
            
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"chat-text"]) {
        
        NSMutableArray *peerMessages = [self.peersMessages objectForKey:peer];
        if (peerMessages) {
            [peerMessages addObject:(ChatMessage *)msg.content];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailNotif" object:nil];
            
            // Set the peer unread state to true
            Peer *peerObject = nil;
            for (int i = 0; i < self.objects.count; ++i) {
                Peer *peerI = [self.objects objectAtIndex:i];
                if ([[peerI peerId] isEqualToString:peer]) {
                    peerObject = peerI;
                }
            }
            if (peerObject) {
                peerObject.unreadMessages += 1;
                [self.tableView reloadData];
            }
        }
        
    } else if ([msg.type isEqualToString:@"global-text"]) {
        
        Peer *globalPeer = [self.objects objectAtIndex:0];
        
        if (globalPeer) {
            [globalPeer.chatMessages addObject:(ChatMessage *)msg.content];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailNotif" object:nil];
        
            // Set the peer unread state to true
            globalPeer.unreadMessages += 1;
            [self.tableView reloadData];
        }
        
    }
}

@end
