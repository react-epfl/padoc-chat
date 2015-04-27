//
//  DetailViewController.m
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import "DetailViewController.h"

#import "MHPacket.h"
#import "Message.h"
#import "Peer.h"
#import "ChatMessage.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)printMessage:(ChatMessage *)message {
    
    NSMutableAttributedString *messageString = [[NSMutableAttributedString alloc] initWithAttributedString:[self.textView attributedText]];
    
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    
    // Source
    NSMutableAttributedString *sourceString = [[NSMutableAttributedString alloc] initWithString:message.source
                                                                                     attributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]];
    [messageString appendAttributedString:sourceString];
    
    // Date
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@" ("]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-YYYY HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:message.date];
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:dateString]];
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@") : "]];
    
    // Message
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] initWithString:message.content
                                                                                      attributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]];
    if ([message.source isEqualToString:[UIDevice currentDevice].name]) {
        [contentString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(0, message.content.length)];
    }
    [messageString appendAttributedString:contentString];
    
    // Append the formatted string
    [self.textView setAttributedText:messageString];
}

- (void)setDetailItem:(Peer *)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.title = [@"Chat with " stringByAppendingString:[self.detailItem displayName]];
        
        self.textView.text = @"";
        // Add all messages to the TextView
        for (int i = 0; i < [[self.detailItem chatMessages] count]; ++i) {
            ChatMessage *message = [[self.detailItem chatMessages] objectAtIndex:i];
            [self printMessage:message];
        }
    } else {
        [self.sendButton setEnabled:NO];
        [self.textField setEnabled:NO];
        self.textView.text = @"Please select a peer you want to chat with.";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performTask:) name:@"DetailNotif" object:nil];
    
    [self.textView setSelectable:NO];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)performTask:(id)sender {
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)addMessage:(NSString *)message {
////    self.textView.text = message;
//    [self.textView setText:message];
//    self.textField.text = message;
//}

- (IBAction)send:(id)sender {
    // Send a message containing the entered text
//    Message* msg = [[Message alloc] initWithType:@"chat-text"
//                                     withContent:self.textField.text];
//    
//    MHPacket* packet = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
//                                       withDestinations:[[NSArray alloc] initWithObjects:[self.detailItem peerId], nil]
//                                               withData:[NSKeyedArchiver archivedDataWithRootObject:msg]];
//    
//    NSError *error;
//    
//    [self.socket sendPacket:packet error:&error];
    
    // Create a ChatMessage with the entered text and the peer infos
    ChatMessage *chatMsg = [[ChatMessage alloc] initWithSource:[UIDevice currentDevice].name
                                                      withDate:[NSDate date]
                                                   withContent:self.textField.text];
    // Send this ChatMessage to the destinated peer
    Message* msg = [[Message alloc] initWithType:@"chat-text"
                                     withContent:chatMsg];
    
    MHPacket* packet = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                       withDestinations:[[NSArray alloc] initWithObjects:[self.detailItem peerId], nil]
                                               withData:[NSKeyedArchiver archivedDataWithRootObject:msg]];
    NSError *error;
    
    [self.socket sendPacket:packet error:&error];
    
    // Add the message to the current peer
    [self.detailItem addMessage:chatMsg];
    
    // Add the message to the TextView
    [self printMessage:chatMsg];
    
    // Erase the content of the TextField
    self.textField.text = nil;
}

@end
