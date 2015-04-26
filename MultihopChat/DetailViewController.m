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

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
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
        
        // Add all messages to the TextView
        for (int i = 0; i < [[self.detailItem chatMessages] count]; ++i) {
            ChatMessage *message = [[self.detailItem chatMessages] objectAtIndex:i];
            self.textView.text = [self.textView.text stringByAppendingString:message.source];
            self.textView.text = [self.textView.text stringByAppendingString:@" ("];
            // TODO : Add date
            self.textView.text = [self.textView.text stringByAppendingString:@") : "];
            self.textView.text = [self.textView.text stringByAppendingString:message.content];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addMessage:(NSString *)message {
//    self.textView.text = message;
    [self.textView setText:message];
    self.textField.text = message;
}

- (IBAction)send:(id)sender {
    // Send a message containing the entered text
    Message* msg = [[Message alloc] initWithType:@"chat-text"
                                     withContent:self.textField.text];
    
    MHPacket* packet = [[MHPacket alloc] initWithSource:[self.socket getOwnPeer]
                                       withDestinations:[[NSArray alloc] initWithObjects:[self.detailItem peerId], nil]
                                               withData:[NSKeyedArchiver archivedDataWithRootObject:msg]];
    
    NSError *error;
    
    [self.socket sendPacket:packet error:&error];
    
    // Add the message to the TextView
    self.textView.text = [self.textView.text stringByAppendingString:[UIDevice currentDevice].name];
    self.textView.text = [self.textView.text stringByAppendingString:@" ("];
    // TODO : Add date
    self.textView.text = [self.textView.text stringByAppendingString:@") : "];
    self.textView.text = [self.textView.text stringByAppendingString:self.textField.text];
    
    // Erase the content of the TextField
    self.textField.text = nil;
}

@end
