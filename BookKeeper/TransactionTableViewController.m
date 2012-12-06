//
//  TransactionTableViewController.m
//  BookKeeper
//
//  Created by Gu, Hong on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TransactionTableViewController.h"
#import "TransactionViewController.h"

@implementation TransactionTableViewController

@synthesize pendingTransactions, completedTransactions, balance, document, titleLabel;

-(void)transactionsDocumentContentsUpdated:(MyTransactionsDocument *)transactionsDocument{
    self.pendingTransactions = transactionsDocument.transactions;
    [(UITableView *)self.view reloadData];
    
    NSLog(@"The transactions are loaded from iCloud.");
}

- (NSString *) inDollarFormat: (double) value{
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    return [formatter stringFromNumber: [NSNumber numberWithDouble: value]];
}

-(void) ubiquitousKeyValueStoreDidChange: (NSNotification *)notification{
    double newBalance = [[NSUbiquitousKeyValueStore defaultStore] doubleForKey:@"balance"];
    NSLog(@"Balance is updated to %f in iCloud.", newBalance);
    self.balance = newBalance;
}

-(UILabel *)titleLabel{
    if (titleLabel == nil) {
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 27)];
        titleLabel.textAlignment =  UITextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.userInteractionEnabled = YES;
    }
    return titleLabel;
}

- (void) setBalance:(double)a_balance{
    if (balance != a_balance){
        balance = a_balance;
        [(UITableView *)self.view reloadData]; 
    }
    //self.title = [NSString stringWithFormat:@"Balance: %@", [self inDollarFormat: balance]];
    self.titleLabel.text = [NSString stringWithFormat:@"Balance: %@", [self inDollarFormat: balance]];
}


- (NSMutableDictionary *)loadTransactionsFromFile:(NSString *)filename {
    NSError *error = nil;
    NSPropertyListFormat format;
    NSMutableDictionary *loadedTransactions;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    NSLog(@"Initializing transactions from plist file: %@", filePath);
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:filePath];
    if (plistXML){
        loadedTransactions = (NSMutableDictionary *)[[NSPropertyListSerialization
                                                       propertyListWithData:plistXML
                                                       options:NSPropertyListMutableContainersAndLeaves
                                                       format:&format
                                                       error:&error] retain];
        if (!loadedTransactions) {
            NSLog(@"Error reading plist: %@, format: %d", error, format);
            [error release];
        }
    }else{
        loadedTransactions = [[NSMutableDictionary alloc] initWithCapacity: 10];
    }
    
    return loadedTransactions;
}

- (NSMutableDictionary *)transactions{
    if (!pendingTransactions){
        pendingTransactions = [self loadTransactionsFromFile:@"transactions.plist"];
    }

    if (!completedTransactions) {
        completedTransactions = [self loadTransactionsFromFile:@"history.plist"];
    }
    
    if (historyView == YES) {
        return completedTransactions;
    }else {
        return pendingTransactions;
    }
    
}


- (NSMutableArray *)dates{
    if (historyView == NO) {
        return [NSMutableArray arrayWithArray:[[self.transactions allKeys] sortedArrayUsingSelector:@selector(compare:)]]; //auto released
    }else {
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
        return [NSMutableArray arrayWithArray:[[self.transactions allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject: sortOrder]]];
    }
}

- (void)addTransaction:(id)sender{
    TransactionViewController *addViewController = [[TransactionViewController alloc] initWithNibName:@"TransactionViewController" bundle: nil];
    addViewController.transactions = self.transactions;
    [self.navigationController pushViewController:addViewController animated:YES];
    [addViewController release];
}

- (void)purgeTransactions:(id)sender{
    [self.completedTransactions removeAllObjects];
    [(UITableView *)self.view reloadData]; 
}

- (void)cancelUpdateBalance:(id)sender{
    //self.navigationItem.titleView = nil;
    self.navigationItem.titleView = self.titleLabel;
    //self.title = [NSString stringWithFormat:@"Balance: %@", [self inDollarFormat: balance]];
    self.navigationItem.leftBarButtonItem = toggleButton;
}

- (void)toggleTransactions:(id)sender{
    if (historyView == YES) {
        historyView = NO;
        [toggleButton setTitle:@"Completed"];
        self.navigationItem.rightBarButtonItem = addButton;
    }else{
        historyView = YES;
        [toggleButton setTitle:@"Pending"];
        self.navigationItem.rightBarButtonItem = editButton;
    }
    [(UITableView *)self.view reloadData];
}

- (void)updateBalance:(id)sender{
        
    self.navigationItem.leftBarButtonItem = cancelButton;

    self.navigationItem.titleView = textFieldRounded;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (!self.navigationItem.titleView) return; //This is when cancel button is clicked.
    UITextField *balanceField = (UITextField *)self.navigationItem.titleView;
    NSString *newBalance = balanceField.text;
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSNumber *balanceNumber = [formatter numberFromString:newBalance];
    //self.navigationItem.titleView = nil;
    self.navigationItem.titleView = self.titleLabel;
    self.navigationItem.leftBarButtonItem = toggleButton;
    self.balance = [balanceNumber doubleValue];
    
    NSLog(@"Saving new balance %f to iCloud.", self.balance);
    NSUbiquitousKeyValueStore* keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [keyValueStore setDouble: self.balance forKey: @"balance"];
    [keyValueStore synchronize];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.location == 0 && string.length == 0) {
        return YES;
    }
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([newText isEqualToString:@"-"])
        return YES;
    
    // Set up number formatter…
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    NSNumber *replaceNumber = [formatter numberFromString:newText];
    
    return !(replaceNumber == nil) ;
}


- (void)handleLongPress:(UILongPressGestureRecognizer*)sender { 
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"Long press Ended");
    }
    else {
        NSLog(@"Long press detected.");
        [self updateBalance:nil];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    //[transactions release];
    [addButton release];
    [editButton release];
    [cancelButton release];
    [toggleButton release];
    [textFieldRounded release];
    [titleLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Completed" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleTransactions:)];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTransaction:)];
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(purgeTransactions:)];
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelUpdateBalance:)];
    
    
    textFieldRounded = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 120, 27)];
    textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
    textFieldRounded.textColor = [UIColor blackColor]; 
    textFieldRounded.font = [UIFont systemFontOfSize:17.0]; 
    textFieldRounded.placeholder = @"New balance";  //place holder
    textFieldRounded.backgroundColor = [UIColor whiteColor]; 
    textFieldRounded.autocorrectionType = UITextAutocorrectionTypeNo;   
    textFieldRounded.backgroundColor = [UIColor clearColor];
    textFieldRounded.keyboardType = UIKeyboardTypeNumbersAndPunctuation;  
    textFieldRounded.returnKeyType = UIReturnKeyDone;  
    textFieldRounded.clearButtonMode = UITextFieldViewModeWhileEditing;
    textFieldRounded.delegate = self;


    self.navigationItem.titleView = self.titleLabel;
    self.navigationItem.leftBarButtonItem = toggleButton;
    self.navigationItem.rightBarButtonItem = addButton;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self 
                                               action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.0;
    [self.titleLabel addGestureRecognizer:longPress];
    [longPress release];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    self.pendingTransactions = nil;
    self.completedTransactions = nil;
    addButton = nil;
    editButton = nil;
    cancelButton = nil;
    toggleButton = nil;
    textFieldRounded = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [(UITableView *)self.view reloadData]; 
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfTransactionsPastDue
{
    NSInteger i, count = 0;
    NSArray* dates = [[self.pendingTransactions allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSDate *today = [NSDate date];
    
    UIApplication* app = [UIApplication sharedApplication];
    NSArray* oldNotifications = [app scheduledLocalNotifications];
    
    // Clear out the old notification before scheduling a new one.
    if ([oldNotifications count] > 0)
        NSLog(@"Cancelling %d existing notifications.", [oldNotifications count]);
        [app cancelAllLocalNotifications];
    
    for (i = 0; i < [dates count]; i++)
    {
        NSString *dateStr = [dates objectAtIndex: i];
        NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"yyyy/MM/dd"];
        NSDate *thisDate = [dateFormat dateFromString: dateStr];
        
        NSArray *transactionsOfDate = [self.pendingTransactions objectForKey: dateStr];
        NSInteger numberOfTransactionsOfDate = [transactionsOfDate count]; 
        if ([today compare: thisDate] == NSOrderedDescending) {
            count += numberOfTransactionsOfDate;
        }
        else {
            UILocalNotification* notificationOfDate = [[[UILocalNotification alloc] init] autorelease];
            if (notificationOfDate) {
                notificationOfDate.fireDate = thisDate;
                notificationOfDate.timeZone = [NSTimeZone defaultTimeZone];
                notificationOfDate.repeatInterval = 0;
                notificationOfDate.applicationIconBadgeNumber = numberOfTransactionsOfDate + count;
                [[UIApplication sharedApplication] scheduleLocalNotification:notificationOfDate];
                NSLog(@"schedule a notification %d on %@ (%@)", numberOfTransactionsOfDate, [thisDate description], [notificationOfDate.timeZone description]);
            }
        }
    }
    
    
    return count;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.transactions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *transactionsOfDate = [self.transactions objectForKey: [self.dates objectAtIndex: section]];
    return transactionsOfDate.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TransactionsTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    NSArray *transactionsOfDate = [self.transactions objectForKey: [self.dates objectAtIndex: indexPath.section]];
    NSDictionary *transaction = [transactionsOfDate objectAtIndex: indexPath.row];
    cell.textLabel.text = [transaction objectForKey:@"name"];
    NSNumber *value = [transaction objectForKey:@"value"];
    cell.detailTextLabel.text = [self inDollarFormat: [value doubleValue]];//[NSString stringWithFormat:@"%@", value];
    cell.accessoryType = (UITableViewCellAccessoryType)UITableViewCellEditingStyleDelete;
    
    if (historyView == YES) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (historyView == YES)
        return UITableViewCellAccessoryNone;
    else
        return UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.dates objectAtIndex:section];
}

-  (double)endingBalanceInSection:(NSInteger)section
{
    NSInteger i;
    double theBalance = self.balance;
    for (i = 0; i<= section; i++){
        NSArray *transactionsOfDate = [self.transactions objectForKey: [self.dates objectAtIndex: i]];
        NSInteger j;
        for (j=0; j<transactionsOfDate.count; j++){
            NSDictionary *transaction = [transactionsOfDate objectAtIndex: j];
            NSNumber *value = [transaction objectForKey:@"value"];
            if (historyView == NO) {
                theBalance += [value doubleValue];
            }else {
                theBalance -= [value doubleValue];
            }
        }
    }
    return theBalance;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *label = [[[UILabel alloc] init] autorelease];
    double theBalance = [self endingBalanceInSection:section];
    label.text = [self inDollarFormat:theBalance];
    label.textAlignment = UITextAlignmentRight;
    if (theBalance < 0)
        label.textColor = [UIColor redColor];
    return label;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *dateStr = [self.dates objectAtIndex: indexPath.section];
    NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormat setDateFormat:@"yyyy/MM/dd"];
    NSDate *nsDate = [dateFormat dateFromString: dateStr];
    
    NSDate *today = [NSDate date];
    if (historyView == NO && [today compare: nsDate] == NSOrderedDescending) {
        return @"Complete";
    }
    else {
        return @"Delete";
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *dateStr = [self.dates objectAtIndex: indexPath.section];
        NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"yyyy/MM/dd"];
        NSDate *oldDate = [dateFormat dateFromString: dateStr];
        
        NSMutableArray *transactionsOfDate = [self.transactions objectForKey: dateStr];
        NSDictionary *transaction = [[NSDictionary alloc] initWithDictionary:[transactionsOfDate objectAtIndex: indexPath.row]];
        
        if (transactionsOfDate.count == 1){
            [self.transactions removeObjectForKey:[self.dates objectAtIndex: indexPath.section]];
            //[self.dates removeObjectAtIndex: indexPath.section]; //This was needed when dates was a property
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];            
        }else{
            [transactionsOfDate removeObjectAtIndex: indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        NSDate *today = [NSDate date];
        BOOL completeTransaction = [today compare: oldDate] == NSOrderedDescending;
        if (completeTransaction == YES && historyView == NO) {
            NSNumber *amount = [transaction objectForKey:@"value"];
            self.balance = self.balance + [amount doubleValue];
            
            NSLog(@"Saving balance %f to iCloud after deleting one transaction.", self.balance);
            NSUbiquitousKeyValueStore* keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
            [keyValueStore setDouble: self.balance forKey: @"balance"];
            [keyValueStore synchronize];
            
            // add transaction to completedTransactions
            NSMutableArray *completedTransactionsOfDate = [self.completedTransactions objectForKey:dateStr];
            if (!completedTransactionsOfDate) {
                completedTransactionsOfDate = [[NSMutableArray alloc] initWithCapacity:1];
            }
            [completedTransactionsOfDate addObject:transaction];
            [self.completedTransactions setObject:completedTransactionsOfDate forKey:dateStr];
        }   
        
        NSNumber *repeatInterval = [transaction objectForKey:@"repeatInterval"];
        if (completeTransaction == YES && historyView == NO && repeatInterval){
            NSDate *newDate = [[[NSDate alloc] initWithTimeInterval:60*60*24*[repeatInterval intValue] sinceDate: oldDate] autorelease]; 
            NSString *dateKey = [dateFormat stringFromDate:newDate];
            NSMutableArray *transactionsOfNewDate = [self.pendingTransactions objectForKey:dateKey];
            if (!transactionsOfNewDate)
                transactionsOfNewDate = [[NSMutableArray alloc] initWithCapacity:1];
            [transactionsOfNewDate addObject:transaction];
            [self.pendingTransactions setObject:transactionsOfNewDate forKey:dateKey];
        }else{
            [transaction release];
        }

        self.document.transactions = self.pendingTransactions;
        [self.document updateChangeCount:UIDocumentChangeDone];
        NSLog(@"The transaction is deleted from iCloud.");
        
        [(UITableView *)self.view reloadData]; 
        //[tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange: NSMakeRange(indexPath.section, self.dates.count-indexPath.section)] withRowAnimation:UITableViewRowAnimationTop];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (historyView == YES) return;
    
    // Navigation logic may go here. Create and push another view controller.
    TransactionViewController *detailViewController = [[TransactionViewController alloc] initWithNibName:@"TransactionViewController" bundle: nil];
    detailViewController.transactions = self.transactions;
    detailViewController.indexPath = indexPath;
         
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    
}

@end
