//
//  Transaction.h
//  BookKeeper
//
//  Created by Gu, Hong on 11/4/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Transaction : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSDate * date;

@end
