//
//  DetailViewController.h
//  PadocChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MHPadoc.h"
#import "Peer.h"
#import "ChatMessage.h"


@interface DetailViewController : UIViewController

@property (strong, nonatomic) Peer *detailItem;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) MHPadoc *padoc;

- (void)printMessage:(ChatMessage *)message;

@end

