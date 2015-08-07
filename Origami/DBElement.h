//
//  DBElement.h
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBAttachment, DBContact, DBElement, DBMessage;

@interface DBElement : NSManagedObject

@property (nonatomic, retain) NSNumber * elementId;
@property (nonatomic, retain) NSNumber * isSignal;
@property (nonatomic, retain) NSNumber * isFavourite;
@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSDate * archDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * changeDate;
@property (nonatomic, retain) NSNumber * hasAttaches;
@property (nonatomic, retain) NSNumber * changerId;
@property (nonatomic, retain) NSDate * remindDate;
@property (nonatomic, retain) NSNumber * finishState;
@property (nonatomic, retain) NSDate * finishDate;
@property (nonatomic, retain) NSNumber * creatorId;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSNumber * rootElementId;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *participants;
@property (nonatomic, retain) NSSet *attaches;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) DBContact *creator;
@property (nonatomic, retain) NSSet *childElements;
@property (nonatomic, retain) DBElement *rootElement;
@end

@interface DBElement (CoreDataGeneratedAccessors)

- (void)addParticipantsObject:(DBContact *)value;
- (void)removeParticipantsObject:(DBContact *)value;
- (void)addParticipants:(NSSet *)values;
- (void)removeParticipants:(NSSet *)values;

- (void)addAttachesObject:(DBAttachment *)value;
- (void)removeAttachesObject:(DBAttachment *)value;
- (void)addAttaches:(NSSet *)values;
- (void)removeAttaches:(NSSet *)values;

- (void)addMessagesObject:(DBMessage *)value;
- (void)removeMessagesObject:(DBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addChildElementsObject:(DBElement *)value;
- (void)removeChildElementsObject:(DBElement *)value;
- (void)addChildElements:(NSSet *)values;
- (void)removeChildElements:(NSSet *)values;

@end
