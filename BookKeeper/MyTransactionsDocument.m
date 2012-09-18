//
//  MyTransactionsDocument.m
//  BookKeeper
//
//  Created by Gu, Hong on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MyTransactionsDocument.h"

@implementation MyTransactionsDocument

@synthesize transactions, delegate;

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"UIDocument: loadFromContents: state = %d, typeName=%@", self.documentState, typeName);
    
    if ([contents length] > 0) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:contents];
		self.transactions = [[unarchiver decodeObjectForKey:@"transactions"] retain];
		[unarchiver finishDecoding];
		[unarchiver release];
        NSLog(@"UIDocument: Loading %d transactions from the cloud.", self.transactions.count);
    }    
    
    // update transactions in delegate...
    if ([self.delegate respondsToSelector:@selector(transactionsDocumentContentsUpdated:)]) {
        [self.delegate transactionsDocumentContentsUpdated:self];
    }
    
    return YES;
    
}

// ** WRITING **

-(id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"UIDocument: Will save the transactions in the cloud.");
    
    NSMutableData *data = [[[NSMutableData alloc] init] autorelease];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:self.transactions forKey:@"transactions"];
	[archiver finishEncoding];
	[archiver release];
    
    return data;
}

@end
