//
//  DBMessage.h
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBContact, DBElement;

@interface DBMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * messageId;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * textBody;
@property (nonatomic, retain) NSNumber * isNew;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) DBContact *creator;
@property (nonatomic, retain) DBElement *element;

@end
