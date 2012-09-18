//
//  TransactionViewController.m
//  BookKeeper
//
//  Created by Gu, Hong on 6/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TransactionViewController.h"
#import "TransactionTableViewController.h"


@implementation TransactionViewController

@synthesize datePicker, nameField, valueField, repeatInterval, repeat, transactions, indexPath;

- (void) saveTransaction:(id)sender
{
    if (self.indexPath){ //Remove the old transaction
        NSArray *dates = [[self.transactions allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *date = [dates objectAtIndex: self.indexPath.section];
        NSMutableArray *transactionsOfDate = [self.transactions objectForKey: date];
        
        if (transactionsOfDate.count == 1){
            [self.transactions removeObjectForKey:date];
        }else{
            [transactionsOfDate removeObjectAtIndex: indexPath.row];
        }
    }
    
    NSDate *date = [datePicker date];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *dateKey = [dateFormatter stringFromDate:date];
    NSLog(@"%@ -> %@ on date: %@", nameField.text, valueField.text, dateKey);
    
    NSArray *transactionOfDate = [self.transactions objectForKey: dateKey];
    NSMutableArray *mutableTransactionOfDate;
    if (transactionOfDate){
        mutableTransactionOfDate = [NSMutableArray arrayWithArray:transactionOfDate];
    }else{
        mutableTransactionOfDate = [NSMutableArray arrayWithCapacity: 1];
    }
    NSMutableDictionary *transaction = [NSMutableDictionary dictionaryWithObjectsAndKeys:nameField.text, @"name", valueField.text, @"value", nil];
    if (repeat.on)
        [transaction setObject:repeatInterval.text forKey:@"repeatInterval"];
    [mutableTransactionOfDate addObject:transaction];
    [self.transactions setObject:mutableTransactionOfDate forKey: dateKey];
    
    if (indexPath){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    TransactionTableViewController *ttvc = (TransactionTableViewController *)[viewControllers objectAtIndex:[viewControllers count]-2];
    ttvc.document.transactions = self.transactions;
    [ttvc.document updateChangeCount:UIDocumentChangeDone];
    NSLog(@"The transaction is saved to iCloud.");
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [datePicker release];
    [nameField release];
    [valueField release];
    [saveButton release];
    [repeatInterval release];
    [repeat release];
    [indexPath release];
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
    // Do any additional setup after loading the view from its nib.
    
    if (indexPath){
        NSArray *dates = [[self.transactions allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *date = [dates objectAtIndex: indexPath.section];
        NSArray *transactionsOfDate = [self.transactions objectForKey: date];
        NSDictionary *transaction = [transactionsOfDate objectAtIndex:indexPath.row];
        NSLog(@"editing transaction: %@", transaction);
        nameField.text = [transaction objectForKey:@"name"];
        valueField.text = [transaction objectForKey:@"value"];
        NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        datePicker.date = [dateFormat dateFromString: date]; 
        NSString *repeatDays = [transaction objectForKey:@"repeatInterval"];
        if (repeatDays){
            repeatInterval.text = repeatDays;
            repeat.on = YES;
        }else{
            repeatInterval.text = nil;
            repeat.on = NO;
        }
    }else{
        datePicker.date = [NSDate date];
        datePicker.minimumDate = [NSDate date];
    }
    
    datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:(60*60*24*30)];
    
    
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTransaction:)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.datePicker = nil;
    self.nameField = nil;
    self.valueField = nil;
    self.repeatInterval = nil;
    self.repeatInterval = nil;
    saveButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == nameField || (range.location == 0 && string.length == 0)) {
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

- (IBAction) repeatSwitchChanged
{
    if (repeat.on){
        repeatInterval.enabled = YES;
    }else{
        repeatInterval.enabled = NO;
    }
}

@end
