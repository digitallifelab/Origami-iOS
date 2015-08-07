//
//  DatabaseHandler.h
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DBContact.h"
#import "DBElement.h"
#import "DBMessage.h"
#import "DBAttachment.h"

@class DBElement, DBContact, DBAttachment, DBMessage;


typedef void (^InitializationCompletionBlock) (void);

typedef void (^DataBaseCompletionBlock)(NSDictionary *info, NSError *error);
typedef void(^ElementsBlock)(NSArray *elements, NSError *error);
typedef void(^DashboardElementsBlock)(NSDictionary *elementsContainer);
typedef void(^ContactsBlock)(NSArray *contacts, NSError *error);
typedef void(^MessagesBlock)(NSArray *messages, NSError *error);
typedef void(^AttachesBlock)(NSArray *attaches, NSError *error);

@interface DatabaseHandler : NSObject

-(instancetype) initWithCompletionCallBack:(InitializationCompletionBlock)callBack;

-(void) save;

#pragma mark Contacts

-(void)insertContactsToLocalDatabase: (NSSet *)contacts completion:(DataBaseCompletionBlock) completionBlock;

-(void)queryAllContactsCompletion: (ContactsBlock)completionBlock;

-(void)queryParticipantContactsforElement: (DBElement *)element completion: (ContactsBlock)completionBlock;

-(void)addParticipantContacts: (NSSet *)newContacts toElement: (DBElement *)element completion: (DataBaseCompletionBlock)completion;

-(void)removeParticipantContacts: (NSSet *)contactsToRemove fromElement: (DBElement *)element complation: (DataBaseCompletionBlock)copmletion;

-(void)removeContactFromLocalDatabase: (DBContact *)contactToRemove completion: (DataBaseCompletionBlock) completion;

#pragma mark Elements

-(void)insertElements: (NSSet *)elements completion: (DataBaseCompletionBlock)completion;

-(void)deleteElements: (NSSet *)elements completion: (DataBaseCompletionBlock)completion;

-(void)queryDashboardElementsCompletion: (DashboardElementsBlock)completionBlock;

#pragma mark Messages

-(void)insertMessagesToLocalDatabase: (NSSet *)messagesToInsert completion: (DataBaseCompletionBlock)completion;

-(void)queryMessagesForElement: (DBElement *)targetElement completion: (MessagesBlock)completion;

#pragma mark Attaches

-(void)insertAttachesToLocalDataBase: (NSSet *) attachesToInsert completion:(DataBaseCompletionBlock)completion;

-(void)queryAttachesForElenemt:(DBElement *)targetElement completion:(AttachesBlock)completion;

@end
