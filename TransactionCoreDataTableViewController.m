    //
//  TransactionCoreDataTableViewController.m
//  BookKeeper
//
//  Created by Gu, Hong on 11/3/14.
//
//

#import "TransactionCoreDataTableViewController.h"
#import "Transaction.h"

@interface TransactionCoreDataTableViewController ()
{
    BOOL sortByDate;
}
@end

@implementation TransactionCoreDataTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    sortButton = [[UIBarButtonItem alloc] initWithTitle:@"Sort" style:UIBarButtonItemStyleBordered target:self action:@selector(sortTransactions:)];
    self.navigationItem.rightBarButtonItem = sortButton;

    textFieldRounded = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 80, 27)];
    textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
    textFieldRounded.textColor = [UIColor blackColor];
    textFieldRounded.font = [UIFont systemFontOfSize:17.0];
    textFieldRounded.placeholder = @"Search amount";  //place holder
    textFieldRounded.backgroundColor = [UIColor whiteColor];
    textFieldRounded.autocorrectionType = UITextAutocorrectionTypeNo;
    textFieldRounded.backgroundColor = [UIColor clearColor];
    textFieldRounded.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    textFieldRounded.returnKeyType = UIReturnKeyDone;
    textFieldRounded.clearButtonMode = UITextFieldViewModeWhileEditing;
    textFieldRounded.delegate = (id<UITextFieldDelegate>) self;
    self.navigationItem.titleView = textFieldRounded;

    [self sortTransactions:nil];
}

- (void)viewDidUnload
{
    sortButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.fetchedResultsController = nil;  // This will deallocate fetchedResultsController so that it won't call its delegate (self) 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSString *searchValue = textField.text;
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSNumber *searchNumber = [formatter numberFromString:searchValue];
    NSLog(@"Searching amount: %@", searchNumber);

    if (searchNumber == nil) {
        [self.fetchedResultsController.fetchRequest setPredicate:nil];
    } else {
        [self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"value = %@", searchNumber]];
    }
    [self performFetch];
}

- (void)sortTransactions:(id)sender
{
    if (sortByDate == YES) {
        sortByDate = NO;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.context
                                                                          sectionNameKeyPath:@"name"
                                                                                   cacheName:nil];
    } else {
        sortByDate = YES;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.context
                                                                              sectionNameKeyPath:@"date"
                                                                                       cacheName:nil];
    }

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HistoryTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }

    Transaction *transaction = (Transaction *) [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (sortByDate == YES) {
        cell.textLabel.text = transaction.name;
    } else {
        NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"yyyy/MM/dd"];
        cell.textLabel.text = [dateFormat stringFromDate:transaction.date];
    }
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    cell.detailTextLabel.text = [formatter stringFromNumber: [NSNumber numberWithDouble: [transaction.value doubleValue]]];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (sortByDate == YES) {
        NSString *dateStr = [super tableView:tableView titleForHeaderInSection:section];
        NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss +0000"];
        NSDate *nsDate = [dateFormat dateFromString: dateStr];
        [dateFormat setDateFormat:@"yyyy/MM/dd"];
        return [dateFormat stringFromDate:nsDate];
    } else {
        return [super tableView:tableView titleForHeaderInSection:section];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    NSArray *transactions = [sectionInfo objects];
    NSInteger i;
    double total = 0.0;
    for (i = 0; i < transactions.count; i++) {
        Transaction *transaction = (Transaction *)[transactions objectAtIndex: i];
        total += [transaction.value doubleValue];
    }

    UILabel *label = [[[UILabel alloc] init] autorelease];
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    if (sortByDate == YES) {
        label.text = [NSString stringWithFormat:@"Total: %@", [formatter stringFromNumber: [NSNumber numberWithDouble: total]]];
    } else {
        label.text = [NSString stringWithFormat:@"Average: %@", [formatter stringFromNumber: [NSNumber numberWithDouble: total/transactions.count]]];
    }
    label.textAlignment = UITextAlignmentRight;
    return label;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	if (sortByDate == YES)
        return nil; // Disable section index
    else
        return [super tableView: tableView sectionForSectionIndexTitle:title atIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (sortByDate == YES)
        return nil; // Disable section index
    else
        return [super sectionIndexTitlesForTableView:tableView];
}

- (void)dealloc
{
    [textFieldRounded release];
    [sortButton release];
    [super dealloc];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
