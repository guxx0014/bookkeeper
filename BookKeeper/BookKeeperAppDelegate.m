//
//  BookKeeperAppDelegate.m
//  BookKeeper
//
//  Created by Gu, Hong on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BookKeeperAppDelegate.h"
#import "MyTransactionsDocument.h"



@implementation BookKeeperAppDelegate


@synthesize window=_window;

- (void)loadData:(NSMetadataQuery *)query {
    
    // (4) iCloud: the heart of the load mechanism: if texts was found, open it and put it into _document; if not create it an then put it into _document
    
    if ([query resultCount] == 1) {
        // found the file in iCloud
        NSMetadataItem *item = [query resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        
        MyTransactionsDocument *doc = [[MyTransactionsDocument alloc] initWithFileURL:url];
        doc.delegate = ttvc;
        ttvc.document = doc;
        
        [doc openWithCompletionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"AppDelegate: existing document opened from iCloud");
            } else {
                NSLog(@"AppDelegate: existing document failed to open from iCloud");
            }
        }];
    } else {
        // Nothing in iCloud: create a container for file and give it URL
        NSLog(@"AppDelegate: document not found in iCloud.");
        
        NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousPackage = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"MyTransactions.plist"];
        
        MyTransactionsDocument *doc = [[MyTransactionsDocument alloc] initWithFileURL:ubiquitousPackage];
        doc.delegate = ttvc;
        ttvc.document = doc;
        
        [doc saveToURL:[doc fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"AppDelegate: new document save to iCloud");
            [doc openWithCompletionHandler:^(BOOL success) {
                NSLog(@"AppDelegate: new document opened from iCloud");
            }];
        }];
    }
}

- (void)queryDidFinishGathering:(NSNotification *)notification {
    
    // (3) if Query is finished, this will send the result (i.e. either it found our MyTransactions.plist or it didn't) to the next function
    
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    [query stopQuery];
    
    [self loadData:query];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:query];
    _query = nil; // we're done with it
}

-(void)loadDocument {
    
    // (2) iCloud query: Looks if there exists a file called MyTransactions.plist in the cloud
    
    NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
    _query = query;
    //SCOPE
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
    //PREDICATE
    NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, @"MyTransactions.plist"];
    [query setPredicate:pred];
    //FINISHED?
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
    [query startQuery];
    
}


- (void) saveTransactionsToPlist{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pendingPath = [documentsDirectory stringByAppendingPathComponent:@"transactions.plist"];
    NSLog(@"Writing pending transactions to plist file: %@", pendingPath);
    [ttvc.pendingTransactions writeToFile:pendingPath atomically:NO];
    NSString *completedPath = [documentsDirectory stringByAppendingPathComponent:@"history.plist"];
    NSLog(@"Writing completed transactions to plist file: %@", completedPath);
    [ttvc.completedTransactions writeToFile:completedPath atomically:NO];
    
    ttvc.document.transactions = ttvc.pendingTransactions;
    [ttvc.document updateChangeCount:UIDocumentChangeDone];
    NSLog(@"The transactions are saved to iCloud.");
    
    NSLog(@"Saving balance to preference: %f", ttvc.balance);
    [[NSUserDefaults standardUserDefaults] setDouble:ttvc.balance forKey:@"balance"];
    
    NSLog(@"Saving balance to iCloud as well");
    NSUbiquitousKeyValueStore* keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [keyValueStore setDouble: ttvc.balance forKey: @"balance"];
    [keyValueStore synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    ttvc = [[TransactionTableViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] init];
    ttvc.balance = [[NSUserDefaults standardUserDefaults] doubleForKey:@"balance"];
    
    // (1) iCloud: init
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (ubiq) {
        NSLog(@"AppDelegate: iCloud access!");
        [self loadDocument];
        
        NSUbiquitousKeyValueStore *keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        ttvc.balance = [keyValueStore doubleForKey:@"balance"];
        NSLog(@"Loading balance from key value store in iCloud: %f", ttvc.balance);
        
        [[NSNotificationCenter defaultCenter] addObserver:ttvc selector:@selector(ubiquitousKeyValueStoreDidChange:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:keyValueStore];
        
    } else {
        NSLog(@"AppDelegate: No iCloud access (either you are using simulator or, if you are on your phone, you should check settings");
    }
    
    // Core Data
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                     inDomains:NSUserDomainMask] firstObject];
    NSURL *url = [documentsDirectory URLByAppendingPathComponent:@"transactions.db"];
    UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document openWithCompletionHandler:^(BOOL success) {
            if (success && document.documentState == UIDocumentStateNormal) {
                ttvc.context = document.managedObjectContext;
                NSLog(@"open core data file successfully.");
            };
        }];
    } else {
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
            if (success && document.documentState == UIDocumentStateNormal) {
                ttvc.context = document.managedObjectContext;
                NSLog(@"create core data file successfully.");
                [ttvc populateDBFromPlist];
                NSLog(@"Populate core data file succcessfully.");
            };
        }];
    }

    [nav pushViewController: ttvc animated: NO];
    [ttvc release];
    [self.window addSubview: nav.view];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveTransactionsToPlist];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[ttvc numberOfTransactionsPastDue]];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self saveTransactionsToPlist];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
