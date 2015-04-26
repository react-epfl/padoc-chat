//
//  DetailViewController.h
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MHMulticastSocket.h"


@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) MHMulticastSocket *socket;

- (void)addMessage:(NSString *)message;

@end

