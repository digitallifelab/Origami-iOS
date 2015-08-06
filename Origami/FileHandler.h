//
//  FileHandler.h
//  KARA
//
//  Created by CloudCraft on 17.04.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>


@interface FileHandler : NSObject

-(NSArray *) getCountriesFromDisk;

-(NSArray *) getLanguagesFromDisk;

-(void) saveCountriesToDisk:(NSArray *)countries;

-(void) saveLanguagesToDisk:(NSArray *)languages;

-(NSURL *) urlForAmbience;
-(NSURL *) urlForEmotionAtIndex:(NSInteger)emotionIndex;

-(void) saveCurrentUserToDisk:(NSDictionary *)userInfo;
-(NSDictionary *)getSavedUser;
-(void) deleteSavedUser;

-(void) saveCurrentMessagesToDisk:(NSArray *)messages;
-(NSArray *)getSavedMessages;
-(void) deleteSavedMessages;

-(NSString *) saveTempVideoToDisk:(NSData *)videoData completionPath:(void(^)(NSString *path)) completion;

-(void)deleteTempVideo;


-(void) saveFileToDisc:(NSData *)file fileName:(NSString *)fileName completion:(void(^)(NSString *filePath, NSError *error)) completionBlock;

-(void) loadFileNamed:(NSString *)fileName completion:(void(^)(NSData *fileData, NSError *readingError)) completionBlock;

-(void) eraseFileNamed:(NSString *) fileName completion:(void(^) (BOOL succes, NSError *eraseError)) completionBlock;

///  AVATARS
-(void) saveAvatar:(NSData *)imageData forLoginName:(NSString *)loginName completion:(void(^)(NSError* saveError)) completionBlock;
-(void) loadAvatarDataForLoginName:(NSString *)loginName completion:(void(^)(NSData* avatarData, NSError* saveError)) completionBlock;

@end
