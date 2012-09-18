//
//  MyTransactionsDocument.h
//  BookKeeper
//
//  Created by Gu, Hong on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MyTransactionsDocument : UIDocument {
    NSMutableDictionary *transactions;
    id delegate;
}

@property (nonatomic, assign) NSMutableDictionary *transactions;
@property (nonatomic, assign) id delegate;

@end
