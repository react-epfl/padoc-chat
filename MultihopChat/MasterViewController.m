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

//GETT changed MHMulticastSocketDelegate to MHPadocDelegate
@interface MasterViewController () <MHPadocDelegate>

@property NSMutableArray *objects;
@property NSMutableDictionary *peersMessages;
@property (strong, nonatomic) MHPadoc *padoc;

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
    self.padoc = [[MHPadoc alloc] initWithServiceType:@"chat"];
    self.padoc.delegate = self;
    
    // For background mode
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setPadoc:self.padoc];
    
    // Join the groups
    [self.padoc joinGroup:GLOBAL];
    [self.padoc joinGroup:[self.padoc getOwnPeer]];
    
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
    
    //GETT added self.padoc getOwnPeer to the msg
    Message* msg = [[Message alloc] initWithType:@"discovery"
                                     withContent:[[NSArray alloc] initWithObjects:[UIDevice currentDevice].name, [self.padoc getOwnPeer], nil]];
    
    NSError *error;
    
    [self.padoc multicastMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
              toDestinations:[[NSArray alloc] initWithObjects:GLOBAL, nil]
                       error:&error];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        //GETT
        NSLog(@"preparingForSegue WTF");
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Peer *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        [controller setPadoc:self.padoc];
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
    
    int hopsCount = [self.padoc hopsCountFromPeer:peer.peerId];
    NSString *hopsCountText = hopsCount == 1 ? @"hop" : @"hops";
    NSString *hopsText = @"";
    if (![peer.peerId isEqualToString:GLOBAL]) {
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

- (void)mhPadoc:(MHPadoc *)mhPadoc
          failedToConnect:(NSError *)error {
    
}

//GETT
//- (void)mhPadoc:(MHPadoc *)mhPadoc
//didReceiveMessage:(NSData *)data
//        fromPeer:(NSString *)peer
//   withTraceInfo:(NSArray *)traceInfo {

- (void)mhPadoc:(MHPadoc *)mhPadoc
deliverMessage:(NSData *)data
       fromGroups:(NSArray *)groups {

    Message* msg = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if ([msg.type isEqualToString:@"discovery"]) {
        //GET added NSLog, it works
        NSLog(@"received discovery message");
        
        // Reply to the discovery request
        
        
        //GETT changed [UIDevice currentDevice].name to NSArray and added peerID
        Message* sentMsg = [[Message alloc] initWithType:@"discovery-reply"
                                             withContent:[[NSArray alloc] initWithObjects:[UIDevice currentDevice].name, [self.padoc getOwnPeer], nil]];
        
        NSError *error;
        
        [self.padoc multicastMessage:[NSKeyedArchiver archivedDataWithRootObject:sentMsg]
                  toDestinations:groups
                           error:&error];
        
        //GETT : change peer delivery to group delivery
        // Add the peer that initiated the discovery to the list of peers if not already present
        
        //msgContent is a NSArray containing the name of the peer and his ID.
        NSString *peerDisplayName = [(NSArray*)msg.content firstObject];
        NSString *peerID = [(NSArray*)msg.content objectAtIndex:1];
        
        //create peerObject
        //GETT changed peer to peerID
        Peer *peerObject = [[Peer alloc] initWithPeerId:peerID withDisplayName:peerDisplayName];
        
        //if peerObject is not in self.objects
        if (![self.objects containsObject:peerObject]) {
            //include it
            [self.objects addObject:peerObject];
            
            //and fetch messages for said peer
            NSMutableArray *peerMessages = [self.peersMessages objectForKey:peerID];
            
            //If there are messages, set them
            if (peerMessages) {
                [peerObject setChatMessages:peerMessages];
            } else {
                [self.peersMessages setValue:peerObject.chatMessages forKey:peerObject.peerId];
            }
            
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"discovery-reply"]) {
        //GET added NSLog, it works
        NSLog(@"received dicovery-reply message");
        
        //GETT changed NSString to NSArray and fetched first object
        NSString *peerDisplayName =[(NSArray*)msg.content firstObject];
        NSString *peerID = [(NSArray*)msg.content objectAtIndex:1];
        NSLog(@"display name received is %@ and peerID is %@", peerDisplayName, peerID);
        
        //GETT changed groups to peerID
        Peer *peerObject = [[Peer alloc] initWithPeerId:peerID withDisplayName:peerDisplayName];
        
        if (![self.objects containsObject:peerObject]) {
            [self.objects addObject:peerObject];
            
            //GETT changed groups to peerID
            NSMutableArray *peerMessages = [self.peersMessages objectForKey:peerID];
            if (peerMessages) {
                [peerObject setChatMessages:peerMessages];
            } else {
                [self.peersMessages setValue:peerObject.chatMessages forKey:peerObject.peerId];
            }
            
            [self.tableView reloadData];
        }
        
    } else if ([msg.type isEqualToString:@"chat-text"]) {
        
        //GETT changed NSString to NSArray and fetched first object
        NSLog(@"Received CHAT MSG");
        NSLog(@"the msg.content is : %@, and the source is : %@", ((ChatMessage*)msg.content).content, ((ChatMessage*)msg.content).source);
        NSString *msgSource = ((ChatMessage*)msg.content).source;
        
        //GETT changed groups to msgSource
        NSMutableArray *peerMessages = [self.peersMessages objectForKey:msgSource];
        if (peerMessages) {
            [peerMessages addObject:(ChatMessage*)msg.content];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailNotif" object:nil];
            
            // Set the peer unread state to true
            Peer *peerObject = nil;
            for (int i = 0; i < self.objects.count; ++i) {
                Peer *peerI = [self.objects objectAtIndex:i];
                
                //GETT changed groups to msgSource
                if ([[peerI peerId] isEqualToString:msgSource]) {
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
            [globalPeer.chatMessages addObject:(ChatMessage*)msg.content];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailNotif" object:nil];
        
            // Set the peer unread state to true
            globalPeer.unreadMessages += 1;
            [self.tableView reloadData];
        }
        
    }
}

@end
