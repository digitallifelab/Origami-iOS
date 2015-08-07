//
//  DBContact.h
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBAttachment, DBElement, DBMessage;

@interface DBContact : NSManagedObject

@property (nonatomic, retain) NSNumber * contactId;
@property (nonatomic, retain) NSString * loginName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSSet *connectedElements;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *attaches;
@property (nonatomic, retain) NSSet *ownElements;
@end

@interface DBContact (CoreDataGeneratedAccessors)

- (void)addConnectedElementsObject:(DBElement *)value;
- (void)removeConnectedElementsObject:(DBElement *)value;
- (void)addConnectedElements:(NSSet *)values;
- (void)removeConnectedElements:(NSSet *)values;

- (void)addMessagesObject:(DBMessage *)value;
- (void)removeMessagesObject:(DBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addAttachesObject:(DBAttachment *)value;
- (void)removeAttachesObject:(DBAttachment *)value;
- (void)addAttaches:(NSSet *)values;
- (void)removeAttaches:(NSSet *)values;

- (void)addOwnElementsObject:(DBElement *)value;
- (void)removeOwnElementsObject:(DBElement *)value;
- (void)addOwnElements:(NSSet *)values;
- (void)removeOwnElements:(NSSet *)values;

@end
