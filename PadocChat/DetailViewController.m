//
//  DetailViewController.m
//  PadocChat
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
    NSString *displayName;
    if([message.source isEqualToString:[self.padoc getOwnPeer]]){
        displayName = [UIDevice currentDevice].name;
    }else{
        displayName = _detailItem.displayName;
    }
    NSMutableAttributedString *sourceString = [[NSMutableAttributedString alloc] initWithString:displayName
                                                                                     attributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]];
    [messageString appendAttributedString:sourceString];
    
    // Date
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@" ("]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if ([[NSCalendar currentCalendar] isDateInToday:message.date]) {
        [dateFormatter setDateFormat:@"HH:mm:ss"];
    } else {
        [dateFormatter setDateFormat:@"dd.MM.YYYY HH:mm:ss"];
    }
    NSString *dateString = [dateFormatter stringFromDate:message.date];
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:dateString]];
    [messageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@") : "]];
    
    // Message
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] initWithString:message.content
                                                                                      attributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]];
    if ([message.source isEqualToString:[self.padoc getOwnPeer]]) {
        [contentString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(0, message.content.length)];
    }
    [messageString appendAttributedString:contentString];
    
    // Append the formatted string
    [self.textView setAttributedText:messageString];
    
    // Scroll to the bottom of the TextView
//    [self.textView setContentOffset:[self.textView contentOffset] animated:NO];
    [self.textView scrollRangeToVisible:NSMakeRange([self.textView.attributedText length] - 1, 1)];
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
        if ([[self.detailItem peerId] isEqualToString:@"global"]) {
            self.title = @"Global chat room";
        } else {
            self.title = [@"Chat with " stringByAppendingString:[self.detailItem displayName]];
        }
        
        self.textView.text = @"";
        // Add all messages to the TextView
        for (int i = 0; i < [[self.detailItem chatMessages] count]; ++i) {
            ChatMessage *message = [[self.detailItem chatMessages] objectAtIndex:i];
            [self printMessage:message];
        }
        
        [self.detailItem setUnreadMessages:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MasterNotif" object:nil];
    } else {
        [self.sendButton setEnabled:NO];
        [self.textField setEnabled:NO];
        self.textView.text = @"Please select a peer you want to chat with.";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performTask:)
                                                 name:@"DetailNotif"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self.textView setSelectable:NO];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)performTask:(id)sender {
    [self configureView];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.view.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.view.frame = CGRectMake(0, 0, keyboardFrameEnd.size.width, keyboardFrameEnd.origin.y);
    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)send:(id)sender {
    
    // Create a ChatMessage with the entered text and the peer infos
    ChatMessage *chatMsg = [[ChatMessage alloc] initWithSource:[self.padoc getOwnPeer]
                                                      withDate:[NSDate date]
                                                   withContent:self.textField.text];
    
    // Send this ChatMessage to the destinated peer
    Message* msg = nil;
    if ([[self.detailItem peerId] isEqualToString:@"global"]) {
        // GLOBAL chat room
        msg = [[Message alloc] initWithType:@"global-text"
                                         withContent:chatMsg];
    } else {
        // 1-to-1 chat
        msg = [[Message alloc] initWithType:@"chat-text"
                                         withContent:chatMsg];
    }
    
    NSError *error;
    [self.padoc multicastMessage:[NSKeyedArchiver archivedDataWithRootObject:msg]
              toDestinations:[[NSArray alloc] initWithObjects:[self.detailItem peerId], nil]
                       error:&error];
    
    // Add the message to the current peer
    [self.detailItem addMessage:chatMsg];
    
    // Add the message to the TextView
    [self printMessage:chatMsg];
    
    // Erase the content of the TextField
    self.textField.text = nil;
}

@end
