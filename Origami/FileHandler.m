//
//  FileHandler.m
//  KARA
//
//  Created by CloudCraft on 17.04.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import "FileHandler.h"

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

-(NSString *)pathForUserAvatar
{
    NSString *avatarPath = [[self rootDocumentsDirectory] stringByAppendingPathComponent:@"avatar.png"];
    return avatarPath;
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

-(UIImage *)getUserAvatarFromDisk
{
    NSString *imagePath = [self pathForUserAvatar];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    if (imageData)
    {
        UIImage *userImage = [UIImage imageWithData:imageData];
        return userImage;
    }
    return nil;

}

-(void) saveUserAvatarToDisk:(UIImage *)userImage
{
    NSString *imagePath = [self pathForUserAvatar];
    NSData *imageData = UIImagePNGRepresentation(userImage);
    if (imageData)
    {
        [imageData writeToFile:imagePath atomically:YES];
    }
}

- (BOOL)saveAvatar:(NSData *)fileData forName:(NSString *)userLoginName
{
    NSString *appDocsDir = [self rootDocumentsDirectory];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", appDocsDir, userLoginName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL success = [fileManager createFileAtPath:filePath contents:fileData attributes:nil];
    
    return success;
}

-(NSData *)imageDataForUserAvatarWithUserName:(NSString *)userLoginName;
{
    NSString *avatarURL = [NSString stringWithFormat:@"%@/%@.png",[self rootDocumentsDirectory], userLoginName ];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSData *contents = [fileManager contentsAtPath:avatarURL];
    return contents; //nil if no file
}

#pragma mark EmotionsSound
-(NSURL *)urlForAmbience
{
    NSURL *lvAudioURL = [[NSBundle mainBundle] URLForResource:@"AmbienceSound" withExtension:@"mp3"];
    
    return lvAudioURL;
}

-(NSURL *)urlForEmotionAtIndex:(NSInteger)emotionIndex
{
    //TODO: return the right audio file path
    return nil;
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
//    BOOL didSave = NO;// [userInfo writeToFile:savingPath atomically:YES];
//    
////    NSData *plistFile = [NSData data]
////    NSError * error = nil;
////    BOOL success = [plistFile writeToFile:path options:NSDataWritingAtomic error:&error];
////    NSLog(@"Success = %d, error = %@", success, error);
//    
//    if (!didSave)
//    {
        //NSLog(@"\r - Error Saving User to disk.");
        NSError *lvError;
        NSData *userData = [NSPropertyListSerialization dataWithPropertyList:userInfo format:NSPropertyListXMLFormat_v1_0 options:0 error:&lvError];
        if (lvError)
        {
            //NSLog(@"\r - Error Creating User Data: \n%@", lvError);
        }
        else
        {
            [userData writeToFile:savingPath options:NSDataWritingAtomic error:&lvError];
//            if (lvError)
//            {
//               // NSLog(@"\r - Error Writing User Data: \n%@", lvError);
//            }
//            else
//            {
////                NSLog(@"\r - Saved Current User to Documents___.");
//            }
        }
//    }
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

#pragma mark - Tepm Video
-(NSString *) pathToTempVideo
{
    NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToVideo = [pathToDocs stringByAppendingString:@"/video.mov"];
    return pathToVideo;
}
-(NSString *) saveTempVideoToDisk:(NSData *)videoData completionPath:(void(^)(NSString *path)) completion
{
    NSString *savePath = [self pathToTempVideo];
    NSError *lvError;
    [videoData writeToFile:savePath options:NSDataWritingAtomic error:&lvError];
    
    if (!lvError)
    {
        //NSURL *toReturn = [NSURL URLWithString:savePath];
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        //{
            completion(savePath);
      //  });
        return savePath;
    }
    
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(nil);
    //});
    
    return nil;
}

-(void)deleteTempVideo
{
    NSString *videoPath = [self pathToTempVideo];
    NSFileManager *lvManager = [[NSFileManager alloc] init];
    if ([lvManager fileExistsAtPath:videoPath])
    {
        [lvManager removeItemAtPath:videoPath error:nil];
    }
}
#pragma mark MediaFiles
-(NSString *) pathToFileNamed:(NSString *) fileName
{
    NSString *pathToDocs = [self rootDocumentsDirectory];
    NSString *pathToDirectory = [pathToDocs stringByAppendingString:@"/Origami/Attaches/"];
    
    //check for current directory
    BOOL isDirectory = YES;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:pathToDirectory isDirectory:&isDirectory])
    {
        NSError *lvFolderError;
        BOOL didCreateDicertory = [[NSFileManager defaultManager] createDirectoryAtPath:pathToDirectory withIntermediateDirectories:YES attributes:nil error:&lvFolderError];
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
        
    }
    
    NSString *pathToFile = [pathToDirectory stringByAppendingString:[NSString stringWithFormat:@"%@", fileName]];
    
    return pathToFile;
}
-(void) saveFileToDisc:(NSData *)file fileName:(NSString *)fileName completion:(void(^)(NSString *filePath, NSError *error)) completionBlock
{
    NSString *savePath = [self pathToFileNamed:fileName];
    NSError *lvError;
    BOOL written = [file writeToFile:savePath options:0 error:&lvError];
    
    if (!lvError)
    {
        NSLog(@" ->  file %@ written = %d", fileName, written);
        completionBlock(savePath, nil);
        return;
    }
    NSLog(@" ->  file %@ written = %d", fileName, written);
    NSLog(@"......Failed to save file to disc: \n%@", lvError.localizedDescription);
    completionBlock(nil, lvError);
}

-(void) loadFileNamed:(NSString *)fileName completion:(void(^)(NSData *fileData, NSError *readingError)) completionBlock
{
    NSString *filePath = [self pathToFileNamed:fileName];
    
    //check for current file
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        NSLog(@" ... Error. File \" %@ \"does not exist at Attaches directory.", fileName);
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


-(void) eraseFileNamed:(NSString *)fileName completion:(void (^)(BOOL, NSError *))completionBlock
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
@end
