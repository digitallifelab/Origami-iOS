//
//  DBAttachment.h
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBContact, DBElement;

@interface DBAttachment : NSManagedObject

@property (nonatomic, retain) NSNumber * attachId;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) DBElement *element;
@property (nonatomic, retain) DBContact *creator;

@end
