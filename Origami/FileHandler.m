//
//  FileHandler.m
//  KARA
//
//  Created by CloudCraft on 17.04.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import "FileHandler.h"
#import <ImageIO/ImageIO.h>
@implementation FileHandler

//-(NSArray *)documentsDirectoryPaths
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                         NSUserDomainMask, YES);
//    return paths;
//}

- (NSString *)rootDocumentsDirectory
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return directory;
}

-(NSString *)pathForCountries
{
    NSString *countryPath = [[self rootDocumentsDirectory]stringByAppendingPathComponent:@"countries.out"];
    return countryPath;
}

-(NSString *)pathForLanguages
{
    NSString *countryPath = [[self rootDocumentsDirectory] stringByAppendingPathComponent:@"languages.out"];
    return countryPath;
}

-(NSString *) pathToAttachesFolder
{
    NSString *attachesFolder = [[self rootDocumentsDirectory] stringByAppendingPathComponent:@"/Origami/Attaches/"];
    
    //check for current directory
    BOOL isDirectory = YES;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:attachesFolder isDirectory:&isDirectory])
    {
        NSError *lvFolderError;
        BOOL didCreateDicertory = [[NSFileManager defaultManager] createDirectoryAtPath:attachesFolder withIntermediateDirectories:YES attributes:nil error:&lvFolderError];
        if (!didCreateDicertory)
        {
            if(lvFolderError)
            {
                NSLog(@"... Error Creating Origami  Attaches folder: \n %@", lvFolderError.description);
                return nil;
            }
            else
            {
                NSLog(@"... Error Creating Origami  Attaches folder: \n Unknown Error");
                return nil;
            }
        }
        else
        {
            //NSLog(@"\n..Created Attaches Folder..\n");
        }
    }
    
    return attachesFolder;
}

-(NSArray *)getCountriesFromDisk
{
    NSString *countriesPath = [self pathForCountries];
    if (countriesPath)
    {
        NSArray *countriesFromDisk = [NSArray arrayWithContentsOfFile:countriesPath];
        return countriesFromDisk;
    }
    return nil;
}

-(NSArray *)getLanguagesFromDisk
{
    NSString *languagesPath = [self pathForLanguages];
    if (languagesPath)
    {
        NSArray *languagesFromDisk = [NSArray arrayWithContentsOfFile:languagesPath];
        return languagesFromDisk;
    }
    return nil;
}

-(void) saveCountriesToDisk:(NSArray *)countries
{
    NSString *countriesPath = [self pathForCountries];

    [countries writeToFile:countriesPath atomically:YES];
}

-(void) saveLanguagesToDisk:(NSArray *)languages
{
    NSString *languagesPath = [self pathForLanguages];
    
    [languages writeToFile:languagesPath atomically:YES];
}

#pragma mark  Avatars


-(NSString *) pathToAvatarFolder
{
    NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToDirectory = [pathToDocs stringByAppendingString:@"/Origami/Avatars/"];
    
    //check for current directory
    BOOL isDirectory = YES;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToDirectory isDirectory:&isDirectory])
    {
        NSError *lvFolderError;
        BOOL didCreateDicertory = [[NSFileManager defaultManager] createDirectoryAtPath:pathToDirectory withIntermediateDirectories:YES attributes:nil error:&lvFolderError];
        if (!didCreateDicertory)
        {
            if(lvFolderError)
            {
                NSLog(@"... Error Creating Origami  Avatars folder: \n %@", lvFolderError.description);
                return nil;
            }
            else
            {
                NSLog(@"... Error Creating Origami  Avatars folder: \n Unknown Error");
                return nil;
            }
        }
        else
        {
            //NSLog(@"\n ...Did Create Avatars Folder... \n");
        }
    }
    return pathToDirectory;
}

-(void) saveAvatar:(NSData *)imageData forLoginName:(NSString *)loginName completion:(void(^)(NSError* saveError)) completionBlock
{
    if (completionBlock != nil)
    {
        NSString *avatarsFolderDirectory = [self pathToAvatarFolder];
        
        if (avatarsFolderDirectory != nil)
        {
            NSString *fileName = [loginName stringByAppendingString:@".jpg"];
            NSString *filePath = [avatarsFolderDirectory stringByAppendingString:fileName];
            
            NSError *writingError = nil;
            BOOL avatarWritten = [imageData writeToFile:filePath options:NSDataWritingAtomic error:&writingError];
            
            if (avatarWritten)
            {
                completionBlock(nil);
            }
            else if (writingError)
            {
                completionBlock(writingError);
            }
            else
            {
                NSError *unknownError = [NSError errorWithDomain:@"Origami.AvatarSavingError" code:405 userInfo:@{NSLocalizedDescriptionKey:@"Unknown Error while saving avatar to disc"}];
                completionBlock(unknownError);
            }
        }
        else
        {
            NSError *noFolderError = [NSError errorWithDomain:@"Origami.AvatarSavingError" code:406 userInfo:@{NSLocalizedDescriptionKey:@"No Directory For Avatars."}];
            completionBlock(noFolderError);
        }
    }
    
}

-(void) loadAvatarDataForLoginName:(nonnull NSString *)loginName completion:(nullable void(^)(NSData * __nullable avatarData, NSError * __nullable saveError)) completionBlock
{
    NSString *pathToFolder = [self pathToAvatarFolder];
    if (pathToFolder != nil)
    {
        NSString *fileName = [loginName stringByAppendingString:@".jpg"];
        NSString *filePath = [pathToFolder stringByAppendingString:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath: filePath])
        {
            NSData *file = [NSData dataWithContentsOfFile:filePath];
            if (file != nil)
            {
                completionBlock(file, nil);
            }
            else
            {
                NSError *readingError = [NSError errorWithDomain:@"Origami.AvatarReadingError" code:405 userInfo:@{NSLocalizedDescriptionKey:@"Unknown Error while reading avatar from disc"}];
                completionBlock(nil, readingError);
            }
        }
        else
        {
            NSError *noFileError = [NSError errorWithDomain:@"Origami.AvatarSavingError" code:406 userInfo:@{NSLocalizedDescriptionKey:@"No File For Avatar."}];
            completionBlock(nil, noFileError);
        }
    }
    else
    {
        NSError *noFolderError = [NSError errorWithDomain:@"Origami.AvatarSavingError" code:406 userInfo:@{NSLocalizedDescriptionKey:@"No Directory For Avatars."}];
        completionBlock(nil, noFolderError);
    }
}



#pragma mark User
-(NSString *) pathToUser
{
    NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToUser = [pathToDocs stringByAppendingPathComponent:@"User.plist"];
    return pathToUser;
}
-(void) saveCurrentUserToDisk:(NSDictionary *)userInfo
{
    NSString *savingPath = [self pathToUser];

    NSError *lvError;
    NSData *userData = [NSPropertyListSerialization dataWithPropertyList:userInfo format:NSPropertyListXMLFormat_v1_0 options:0 error:&lvError];
    if (lvError)
    {
        NSLog(@"\r - Error Creating User Data: \n%@", lvError);
    }
    else
    {
        [userData writeToFile:savingPath options:NSDataWritingAtomic error:&lvError];
    }

}

-(NSDictionary *)getSavedUser
{
    NSDictionary *savedUser = [NSDictionary dictionaryWithContentsOfFile:[self pathToUser]];
    return savedUser;
}

-(void) deleteSavedUser
{
    NSString *savingPath = [self pathToUser];
    NSFileManager *lvFileManager = [[NSFileManager alloc] init];
    
    NSError *lvRemoveError;
    if ([lvFileManager fileExistsAtPath:savingPath])
    {
        [lvFileManager removeItemAtPath:savingPath error:&lvRemoveError];
    }
}

#pragma mark Messages
-(NSString *) pathToMessages
{
    NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToMessages = [pathToDocs stringByAppendingString:@"/messages.out"];
    return pathToMessages;
}

-(void) saveCurrentMessagesToDisk:(NSArray *)messages
{
    [messages writeToFile:[self pathToMessages] atomically:YES];
}

-(NSArray *)getSavedMessages
{
    NSArray *savedMessages = [NSArray arrayWithContentsOfFile:[self pathToMessages]];
    return savedMessages;
}

-(void) deleteSavedMessages
{
    NSString *pathToMessages = [self pathToMessages];
    NSFileManager *lvManager = [[NSFileManager alloc] init];
    if ([lvManager fileExistsAtPath:pathToMessages])
    {
        [lvManager removeItemAtPath:pathToMessages error:nil];
    }
}

//#pragma mark - Tepm Video
//-(NSString *) pathToTempVideo
//{
//    NSString *pathToDocs = [self rootDocumentsDirectory];
//    NSString *pathToVideo = [pathToDocs stringByAppendingString:@"/video.mov"];
//    return pathToVideo;
//}
//-(NSString *) saveTempVideoToDisk:(NSData *)videoData completionPath:(void(^)(NSString *path)) completion
//{
//    NSString *savePath = [self pathToTempVideo];
//    NSError *lvError;
//    [videoData writeToFile:savePath options:NSDataWritingAtomic error:&lvError];
//    
//    if (!lvError)
//    {
//        completion(savePath);
//        return savePath;
//    }
//    
//    completion(nil);
//    
//    return nil;
//}

//-(void)deleteTempVideo
//{
//    NSString *videoPath = [self pathToTempVideo];
//    NSFileManager *lvManager = [[NSFileManager alloc] init];
//    if ([lvManager fileExistsAtPath:videoPath])
//    {
//        [lvManager removeItemAtPath:videoPath error:nil];
//    }
//}
#pragma mark - MediaFiles
-(NSString *) pathToFileNamed:(NSString *) fileName
{
    //NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToDirectory = [self pathToAttachesFolder]; //[pathToDocs stringByAppendingString:@"/Origami/Attaches/"];
    
  
    
    NSString *pathToFile = [pathToDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]];
    
    return pathToFile;
}

//-(void) saveFileToDisc:(NSData *)file fileName:(NSString *)fileName completion:(void(^)(NSString *filePath, NSError *error)) completionBlock
- (void)saveFileToDisc:(nonnull NSData *)file fileName:(nonnull NSString *)fileName completion:(nullable void (^)(NSString * __nullable, NSError * __nullable))completionBlock
{
    NSString *savePath = [self pathToFileNamed:fileName];
    NSError *lvError;
    BOOL written = [file writeToFile:savePath options:0 error:&lvError];
    
    if (!lvError)
    {
        NSLog(@" ->  file %@ WAS written = %d", fileName, written);
        completionBlock(savePath, nil);
        return;
    }
    NSLog(@" ->  file %@ NOT written = %d", fileName, written);
    NSLog(@"......Failed to save file to disc: \n%@", lvError.localizedDescription);
    completionBlock(nil, lvError);
}

- (nullable NSData *)synchronouslyLoadFileNamed:(nonnull NSString *)fileName
{
//    if (fileName == nil)
//    {
//        NSLog(@"\n ->  Error while trying to read attach file data for NIL file name.\n");
//        return nil;
//    }
    NSString *filePath = [self pathToFileNamed:fileName];
    
    //check for current file
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        NSLog(@" ... Synchron . Error. File \" %@ \"does not exist at Attaches directory.", fileName);
        
        return nil;
    }
    if (filePath == nil)
    {
        return nil;
    }
    NSError *lvError;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&lvError];
    
    if (fileData && fileData.length > 0)
    {
        return fileData;
    }
    
    if (lvError)
    {
        NSLog(@" \n Attach File Reading Error: %@\n", lvError);
    }
    return nil;
    
}

-(void)loadFileNamed:(nonnull NSString *)fileName completion:(nullable void (^)(NSData * __nullable, NSError * __nullable))completionBlock
{
    NSString *filePath = [self pathToFileNamed:fileName];
    
    //check for current file
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        NSLog(@" ... Asynchron . Error. File \" %@ \"does not exist at Attaches directory.", fileName);
        if (completionBlock)
        {
            NSError *noFileError = [NSError errorWithDomain:@"Origamy.File Reading Error." code:-1021 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"File not found: %@ .", fileName]}];
            completionBlock(nil, noFileError);
        }
        return ;
    }
    if (filePath == nil)
    {
        NSError *lvError = [NSError errorWithDomain:@"File system reading error" code:-1021 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"File not found: %@ .", fileName]}];
        completionBlock(nil,lvError);
        return;
    }
    NSError *lvError;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&lvError];
    
    completionBlock(fileData, lvError); //return (data_or_nil ,  nil_or_error)
}


-(void)eraseFileNamed:(nonnull NSString *)fileName completion:(nullable void (^)(BOOL, NSError * __nullable))completionBlock
{
    
    NSString *pathToTargetFile = [self pathToFileNamed:fileName];
    if (!pathToTargetFile)
    {
        NSError *notFoundError = [NSError errorWithDomain:@"File storage error" code:-2001 userInfo:@{NSLocalizedDescriptionKey : @"FileNotFound at required path."}];
        if (completionBlock)
        {
            completionBlock(NO, notFoundError);
        }
        return;
    }
    
    NSFileManager *fManager = [NSFileManager defaultManager];
    NSError *removingError;
    
    BOOL removed = [fManager removeItemAtPath:pathToTargetFile error:&removingError];
    if (removed)
    {
        if (completionBlock) {
            completionBlock(YES, nil);
        }
    }
    else if (removingError)
    {
        NSLog(@"Did not delete file: %@", removingError.description);
        if (completionBlock) {
            completionBlock(NO, removingError);
        }
    }
}

-(void)eraseAvatarForUserName:(nonnull NSString *)avatarImageName completion:(nullable void (^)(BOOL, NSError * __nullable))completionBlock
{
    NSString *pathToUsersAvatarFolder = [self pathToAvatarFolder];
    if(!pathToUsersAvatarFolder) {
        if (completionBlock != nil )
        {
            completionBlock(NO, [NSError errorWithDomain:@"" code:-100 userInfo:@{NSLocalizedDescriptionKey : @"Avatars Folder was not found"}]);
        }
        
        return;
    }
    
    NSString *avatarNameWithExtention = [avatarImageName stringByAppendingString:@".jpg"];
    NSString *pathToSingleAvatar = [pathToUsersAvatarFolder stringByAppendingString:avatarNameWithExtention];
    NSError *avatarEraseError;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToSingleAvatar])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pathToSingleAvatar error:&avatarEraseError];
        if(avatarEraseError)
        {
            NSLog(@"\n Could not erase user avatar. Reason: %@", avatarEraseError.description);
            if (completionBlock != nil)
            {
                completionBlock(NO, avatarEraseError);
            }
            return;
        }
        
        if (completionBlock != nil)
        {
            completionBlock(YES, nil);
        }
    }
    else
    {
        NSLog(@"\n Could not erase user avatar. Reason: No user avatar found...");
    }
}

-(void)deleteAvatars
{
    //NSLog(@"\n Starting to remove User Avatar....");
    NSString *pathToUsersAvatarFolder = [self pathToAvatarFolder];
    NSError *avatarEraseError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToUsersAvatarFolder])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pathToUsersAvatarFolder error:&avatarEraseError];
        if( avatarEraseError)
        {
            NSLog(@"\n Could not erase user avatars. Reason: %@", avatarEraseError.description);
        }
    }
    else
    {
        NSLog(@"\n Could not erase user avatar. Reason: No users avatar folder found...");
    }
}

-(void)deleteAttachedImages
{
   // NSLog(@"\n Starting to remove attached files...");
    NSString *pathToAvatarsFolder = [self pathToAttachesFolder];
    NSError *eraseError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToAvatarsFolder])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pathToAvatarsFolder error:&eraseError];
        if( eraseError)
        {
            NSLog(@"\n Could not erase attached files. Reason: %@", eraseError.description);
        }
    }
    else
    {
        NSLog(@"\n Could not erase attached files. Reason: No attached filesfound...");
    }
}

-(nullable NSDictionary *)getAllExistingAvatarsPreviews
{
    NSString *pathToAvatarsFolder = [self pathToAvatarFolder];
    NSError *lvError;
    NSArray *contains = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToAvatarsFolder error:&lvError];
    if (contains && contains.count > 0)
    {
        NSMutableDictionary *toReturn = [NSMutableDictionary dictionaryWithCapacity:contains.count];
        for (NSString *anItemName in contains)
        {
            NSError *loopError;
            NSString *singleItemPath = [pathToAvatarsFolder stringByAppendingString:anItemName];
            NSData *fileData = [NSData dataWithContentsOfFile:singleItemPath options:NSDataReadingMappedIfSafe error:&loopError];
            if (fileData != nil)
            {
                NSString *fixedFileName = [anItemName stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
                [toReturn setObject:fileData forKey:fixedFileName];
            }
            
        }
        if (toReturn.count > 0)
        {
            return toReturn;
        }
    }
    else if (lvError)
    {
        return nil;
    }
    
    return nil;
}



@end
