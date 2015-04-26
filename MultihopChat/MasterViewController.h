//
//  MasterViewController.h
//  MultihopChat
//
//  Created by Sven Reber on 26/04/15.
//  Copyright (c) 2015 Sven Reber. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MHMulticastSocket.h"


@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;


@end

