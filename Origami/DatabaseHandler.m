//
//  DatabaseHandler.m
//  Origami
//
//  Created by CloudCraft on 07.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import "DatabaseHandler.h"


#import "Origami-Swift.h"

@interface DatabaseHandler()

@property (nonatomic, strong) NSManagedObjectContext *mainQueueContext;
@property (nonatomic, strong) NSManagedObjectContext *bgQueueContext;
@property (copy) InitializationCompletionBlock callback;

@end

@implementation DatabaseHandler

-(instancetype) initWithCompletionCallBack:(InitializationCompletionBlock)callBack
{
    self = [super init];
    if (self)
    {
        self.callback = callBack;
        [self initializeCoreData];
        
    }
    
    return self;
}

-(void) initializeCoreData
{
    if (self.mainQueueContext)
    {
        return;
    }
    
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OrigamiModel" withExtension:@"momd"];
    if (modelURL == nil)
    {
        NSAssert(false, @"Did not found dataModel in main bundle.");
    }
    
    NSManagedObjectModel *aModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:aModel];
    NSAssert(coordinator, @"Failed to initialize coordinator");
    
    self.mainQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.bgQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.bgQueueContext setPersistentStoreCoordinator:coordinator];
    self.mainQueueContext.parentContext = self.bgQueueContext;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSPersistentStoreCoordinator *psc = self.bgQueueContext.persistentStoreCoordinator;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;
        options[NSSQLitePragmasOption] = @{ @"journal_mode":@"DELETE" };
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"OrigamiDB.sqlite"];
#ifdef DEBUG
        NSLog(@"Database store path: \n  %@ \n", storeURL.absoluteString);
#endif
        NSError *error = nil;
        NSAssert([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error], @"Error initializing PSC: %@\n%@", [error localizedDescription], [error userInfo]);
        
        if (weakSelf.callback != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesByNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
                weakSelf.callback();
                weakSelf.callback = nil;
            });
            
        }
    });
}

-(void) save
{
    if (!self.mainQueueContext.hasChanges && !self.bgQueueContext.hasChanges) {return;}
    
    [self.mainQueueContext performBlockAndWait:^{
        NSError *saveMainError;
        [self.mainQueueContext save:&saveMainError];
        if (!saveMainError)
        {
            [self.bgQueueContext performBlockAndWait:^{
                NSError *saveBgError;
                [self.bgQueueContext save:&saveBgError];
                if (saveBgError)
                {
                    NSLog(@" -> Did not save backround queue context: Error: \n%@ \n error info: \n%@", saveMainError.localizedDescription, saveMainError.userInfo);
                }
            }];
        }
        else
        {
            NSLog(@" -> Did not save main queue context: Error: \n%@ \n error info: \n%@", saveMainError.localizedDescription, saveMainError.userInfo);
        }
        
    }];
}

-(void) savePrivateContext
{
    if (![self.bgQueueContext hasChanges]) return;
    
    [self.bgQueueContext performBlockAndWait:^{
    
        NSError *saveBGerror;
        
        [self.bgQueueContext save:&saveBGerror];
    }];
}

-(void) mergeChangesByNotification:(NSNotification *)contextNotification
{
    //http://mikeabdullah.net/merging-saved-changes-betwe.html
    NSSet *updatedObjects = [contextNotification.userInfo objectForKey:NSUpdatedObjectsKey];
    for (NSManagedObject *updatedObject in updatedObjects)
    {
        [self.mainQueueContext existingObjectWithID:updatedObject.objectID error:nil];
    }
    
    [self.mainQueueContext mergeChangesFromContextDidSaveNotification:contextNotification];
}


#pragma mark Contacts

-(void)insertContactsToLocalDatabase: (NSSet *)contacts completion:(DataBaseCompletionBlock) completionBlock
{
    
}

-(void)queryAllContactsCompletion: (ContactsBlock)completionBlock
{
    
}

-(void)queryParticipantContactsforElement: (DBElement *)element completion: (ContactsBlock)completionBlock
{
    
}

-(void)addParticipantContacts: (NSSet *)newContacts toElement: (DBElement *)element completion: (DataBaseCompletionBlock)completion
{
    
}

-(void)removeParticipantContacts: (NSSet *)contactsToRemove fromElement: (DBElement *)element complation: (DataBaseCompletionBlock)copmletion
{
    
}

-(void)removeContactFromLocalDatabase: (DBContact *)contactToRemove completion: (DataBaseCompletionBlock) completion
{
    
}

-(DBContact *)queryContactById:(NSNumber *)contactId
{
    
    NSPredicate *elementIdPred = [NSPredicate predicateWithFormat:@"contactId == %@", contactId];
    NSError *fetchError;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"DBContact"];
    
    request.predicate = elementIdPred;
    
    NSArray *foundElements = [self.bgQueueContext executeFetchRequest:request error:&fetchError];
    if (foundElements.count > 0)
    {
        return [foundElements firstObject];
    }
    return nil;
    
}

#pragma mark Elements

-(void)insertElements: (NSSet *)elements completion: (DataBaseCompletionBlock)completion
{
    if (!elements)
    {
        if (completion != nil)
        {
            NSError *noSetError = [NSError errorWithDomain:@"Origami.DatabaseError." code:7001 userInfo:@{NSLocalizedDescriptionKey:@"metrod recieved no required parameter"}];
            completion(nil, noSetError);
        }
        return;
    }
    else if (elements.count < 1)
    {
        if (completion != nil)
        {
            NSError *emptySetError = [NSError errorWithDomain:@"Origami.DatabaseError." code:7002 userInfo:@{NSLocalizedDescriptionKey:@"metrod recieved an empty required parameter"}];
            completion(nil, emptySetError);
        }
        return;
    }
    else
    {
        for (Element *elementObject in elements.allObjects)
        {
            if (![elementObject isKindOfClass:[Element class]])
            {
                continue;
            }
            
            DBElement *existingDBelement = [self queryElementByElementId:elementObject.elementId];
            if (existingDBelement != nil)
            {
                NSLog(@" Updating existing element");
                existingDBelement.elementId = elementObject.elementId;
                existingDBelement.rootElementId = elementObject.rootElementId;
                existingDBelement.type = elementObject.typeId;
                existingDBelement.title = elementObject.title;
                existingDBelement.details = elementObject.details;
                existingDBelement.isSignal = elementObject.isSignal;
                existingDBelement.isFavourite = elementObject.isFavourite;
                existingDBelement.hasAttaches = elementObject.hasAttaches;
                existingDBelement.creatorId = elementObject.creatorId;
                existingDBelement.finishState = elementObject.finishState;
                existingDBelement.changerId = elementObject.changerId;
                existingDBelement.createDate = [elementObject.createDate dateFromServerDateString];
                existingDBelement.finishDate = elementObject.finishDate;
                existingDBelement.remindDate = elementObject.remindDate;
                existingDBelement.archDate = [elementObject.archiveDate dateFromServerDateString];
                existingDBelement.changeDate = [elementObject.changeDate dateFromServerDateString];
                
            }
            else
            {
                NSLog(@" Inserting new element");
                DBElement *dbElement = [NSEntityDescription insertNewObjectForEntityForName:@"DBElement" inManagedObjectContext:self.bgQueueContext];
                dbElement.elementId = elementObject.elementId;
                dbElement.rootElementId = elementObject.rootElementId;
                dbElement.type = elementObject.typeId;
                dbElement.title = elementObject.title;
                dbElement.details = elementObject.details;
                dbElement.isSignal = elementObject.isSignal;
                dbElement.isFavourite = elementObject.isFavourite;
                dbElement.hasAttaches = elementObject.hasAttaches;
                dbElement.creatorId = elementObject.creatorId;
                dbElement.finishState = elementObject.finishState;
                dbElement.changerId = elementObject.changerId;
                dbElement.createDate = [elementObject.createDate dateFromServerDateString];
                dbElement.finishDate = elementObject.finishDate;
                dbElement.remindDate = elementObject.remindDate;
                dbElement.archDate = [elementObject.archiveDate dateFromServerDateString];
                dbElement.changeDate = [elementObject.changeDate dateFromServerDateString];
            }
        }
        
        [self savePrivateContext];
        
        completion(@{},nil);
    }
}

-(void)deleteElements: (NSSet *)elements completion: (DataBaseCompletionBlock)completion
{
    
}

-(void)queryDashboardElementsCompletion: (DashboardElementsBlock)completionBlock
{
    NSPredicate *dashboardSignalsPredicate = [NSPredicate predicateWithFormat:@"isSignal == TRUE"];
    NSPredicate *dashboardFavouritePredicate = [NSPredicate predicateWithFormat:@"isFavourite == TRUE"];
    NSPredicate *dashboardAllPredicate = [NSPredicate predicateWithFormat:@"rootElementId == 0"];
    NSError *signalsError;
    NSError *favouritesError;
    NSError *usualElementsError;
    
    NSFetchRequest *signalsRequest = [[NSFetchRequest alloc] initWithEntityName:@"DBElement"];
    signalsRequest.predicate = dashboardSignalsPredicate;
    NSFetchRequest *favouriteRequest = [[NSFetchRequest alloc] initWithEntityName:@"DBElement"];
    favouriteRequest.predicate = dashboardFavouritePredicate;
    NSFetchRequest *usualElementsRequest = [[NSFetchRequest alloc] initWithEntityName:@"DBElement"];
    usualElementsRequest.predicate = dashboardAllPredicate;
    signalsRequest.returnsObjectsAsFaults = NO;
    favouriteRequest.returnsObjectsAsFaults = NO;
    usualElementsRequest.returnsObjectsAsFaults = NO;
   
    NSArray *signalElements = [self.mainQueueContext executeFetchRequest:signalsRequest error:&signalsError];
    NSArray *favouriteElements = [self.mainQueueContext executeFetchRequest:favouriteRequest error:&favouritesError];
    NSArray *usualElements = [self.mainQueueContext executeFetchRequest:usualElementsRequest error:&usualElementsError];
    
    
    if (signalsError)
    {
        NSLog(@"Signals request error : \n%@", signalsError.localizedDescription);
    }
    if (favouritesError)
    {
        NSLog(@"Favourites request error : \n %@", favouritesError.localizedDescription);
    }
    
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:3];
    if (signalElements.count > 0)
    {
        [response setObject:signalElements forKey:@"signals"];
    }
    if (favouriteElements.count > 0)
    {
        [response setObject:favouriteElements forKey:@"favor"];
    }
    if (usualElements.count > 0)
    {
        [response setObject:usualElements forKey:@"usual"];
    }
    
    if (completionBlock != nil)
    {
        completionBlock(response);
    }
}

-(DBElement *)queryElementByElementId:(NSNumber *)elementId
{
    NSPredicate *elementIdPred = [NSPredicate predicateWithFormat:@"elementId == %@", elementId];
    NSError *fetchError;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"DBElement"];
    
    request.predicate = elementIdPred;
    
    NSArray *foundElements = [self.bgQueueContext executeFetchRequest:request error:&fetchError];
    if (foundElements.count > 0)
    {
        return [foundElements firstObject];
    }
    return nil;
}

#pragma mark Messages

-(void)insertMessagesToLocalDatabase: (NSSet *)messagesToInsert completion: (DataBaseCompletionBlock)completion
{
    if (!messagesToInsert)
    {
        if (completion != nil)
        {
            NSError *noSetError = [NSError errorWithDomain:@"Origami.DatabaseError." code:7001 userInfo:@{NSLocalizedDescriptionKey:@"metrod recieved no required parameter"}];
            completion(nil,noSetError);
        }
        return;
    }
    if (messagesToInsert.count < 1)
    {
        if (completion != nil)
        {
            NSError *emptySetError = [NSError errorWithDomain:@"Origami.DatabaseError." code:7002 userInfo:@{NSLocalizedDescriptionKey:@"metrod recieved an empty required parameter"}];
            completion(nil, emptySetError);
        }
        return;
    }
    NSInteger messagesInsertedCount = 0;
    for (Message *lvMessage in messagesToInsert.allObjects)
    {
        if (![lvMessage isKindOfClass:[Message class]])
        {
            continue;
        }
        
        DBMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"DBMessage" inManagedObjectContext:self.bgQueueContext];
        message.messageId = lvMessage.messageId;
        message.textBody = lvMessage.textBody;
        message.dateCreated = lvMessage.dateCreated;
        message.type = lvMessage.typeId;
        message.isNew = lvMessage.isNew;
        
        // try to find contacts and elements for current message, or setup theese values later.
        
        DBElement *foundElement = [self queryElementByElementId:lvMessage.elementId];
        
        if (foundElement != nil)
        {
            message.element = foundElement;
        }
        
        DBContact *foundContact = [self queryContactById:lvMessage.creatorId];
        if (foundContact != nil)
        {
            message.creator = foundContact;
        }
        messagesInsertedCount += 1;
    }
    NSLog(@"Inserted %ld",(long)messagesInsertedCount);
    [self savePrivateContext];
    if (completion != nil)
    {
        completion(@{},nil);
    }
}

-(void)queryMessagesForElement: (DBElement *)targetElement completion: (MessagesBlock)completion
{
    
}

#pragma mark Attaches

-(void)insertAttachesToLocalDataBase: (NSSet *) attachesToInsert completion:(DataBaseCompletionBlock)completion
{
    
}

-(void)queryAttachesForElenemt:(DBElement *)targetElement completion:(AttachesBlock)completion
{
    
}

@end
