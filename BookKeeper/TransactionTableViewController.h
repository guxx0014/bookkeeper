//
//  TransactionTableViewController.h
//  BookKeeper
//
//  Created by Gu, Hong on 5/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTransactionsDocument.h"

@interface TransactionTableViewController : UITableViewController <UITextFieldDelegate> {
    NSMutableDictionary *transactions, *pendingTransactions, *completedTransactions;
    double balance;
    BOOL historyView;
    
    UITextField *textFieldRounded;
    UILabel *titleLabel;
    UIBarButtonItem *historyButton, *addButton, *editButton, *cancelButton;
}
@property (nonatomic) double balance;
@property (retain, nonatomic) UILabel *titleLabel;
@property (retain, nonatomic) NSMutableDictionary *pendingTransactions, *completedTransactions;
@property (strong, nonatomic) MyTransactionsDocument *document;
@property (strong, nonatomic) NSManagedObjectContext *context;

-(void)addTransaction:(id)sender;
-(NSInteger)numberOfTransactionsPastDue;
-(void)transactionsDocumentContentsUpdated:(MyTransactionsDocument *)transactionsDocument;
-(void)populateDBFromPlist;
@end
