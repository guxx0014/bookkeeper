//
//  TransactionViewController.h
//  BookKeeper
//
//  Created by Gu, Hong on 6/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TransactionViewController : UIViewController <UITextFieldDelegate>{
    UIDatePicker *datePicker;
    UITextField *nameField;
    UITextField *valueField;
    UITextField *repeatInterval;
    UISwitch *repeat;
    UIBarButtonItem *saveButton;
    
    NSMutableDictionary *transactions;
    NSIndexPath *indexPath;
}

@property(nonatomic, retain) IBOutlet UIDatePicker *datePicker;
@property(nonatomic, retain) IBOutlet UITextField *nameField;
@property(nonatomic, retain) IBOutlet UITextField *valueField;
@property(nonatomic, retain) IBOutlet UITextField *repeatInterval;
@property(nonatomic, retain) IBOutlet UISwitch *repeat;

@property(nonatomic, assign) NSMutableDictionary *transactions;
@property(nonatomic, retain) NSIndexPath *indexPath;

- (IBAction)repeatSwitchChanged;

@end
