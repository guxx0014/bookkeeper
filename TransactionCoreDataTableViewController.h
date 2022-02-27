//
//  TransactionCoreDataTableViewController.h
//  BookKeeper
//
//  Created by Gu, Hong on 11/3/14.
//
//

#import "CoreDataTableViewController.h"

@interface TransactionCoreDataTableViewController : CoreDataTableViewController
{
    UIBarButtonItem *sortButton;
    UITextField *textFieldRounded;
}

@property (strong, nonatomic) NSManagedObjectContext *context;

@end
