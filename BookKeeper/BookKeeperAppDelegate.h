//
//  BookKeeperAppDelegate.h
//  BookKeeper
//
//  Created by Gu, Hong on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransactionTableViewController.h"

@interface BookKeeperAppDelegate : NSObject <UIApplicationDelegate> {
    TransactionTableViewController *ttvc;
    NSMetadataQuery *_query;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
