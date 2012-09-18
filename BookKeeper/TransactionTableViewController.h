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
    UIBarButtonItem *toggleButton, *addButton, *editButton, *cancelButton;
}
@property (nonatomic) double balance;
@property (retain, nonatomic) UILabel *titleLabel;
@property (retain, nonatomic) NSMutableDictionary *pendingTransactions, *completedTransactions;
@property (strong, nonatomic) MyTransactionsDocument *document;

-(void)addTransaction:(id)sender;
-(NSInteger)numberOfTransactionsPastDue;
-(void)transactionsDocumentContentsUpdated:(MyTransactionsDocument *)transactionsDocument;

@end
