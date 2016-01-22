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

-(nullable NSArray *) getCountriesFromDisk;

-(nullable NSArray *) getLanguagesFromDisk;

-(void) saveCountriesToDisk:(nonnull NSArray *)countries;

-(void) saveLanguagesToDisk:(nonnull NSArray *)languages;

- (NSURL  * _Nullable )applicationDocumentsDirectory;

-(void) saveCurrentUserToDisk:(nonnull NSDictionary *)userInfo;
-(nullable NSDictionary *)getSavedUser;
-(void) deleteSavedUser;

-(void) saveCurrentMessagesToDisk:(nonnull NSArray *)messages;
-(nullable NSArray *)getSavedMessages;
-(void) deleteSavedMessages;

-(void) saveFileToDisc:(nonnull NSData *)file fileName:(nonnull NSString *)fileName completion:( nullable void(^)(NSString * __nullable filePath,  NSError * __nullable error)) completionBlock;

-(void) loadFileNamed:(nonnull NSString *)fileName completion:(nullable void(^)(NSData * __nullable fileData, NSError * __nullable readingError)) completionBlock;
-(nullable NSData * ) synchronouslyLoadFileNamed:(nonnull NSString *)fileName;
-(void) eraseFileNamed:(nonnull NSString *) fileName completion:(nullable void(^) (BOOL succes, NSError * __nullable eraseError)) completionBlock;

///  AVATARS
-(void) saveAvatar:(nonnull NSData *)imageData forLoginName:(nonnull NSString *)loginName completion:(nullable void(^)(NSError * __nullable saveError)) completionBlock;
-(void) loadAvatarDataForLoginName:(nonnull NSString *)loginName completion:(nullable void(^)(NSData * __nullable avatarData, NSError * __nullable saveError)) completionBlock;
-(void) eraseAvatarForUserName:(nonnull NSString *)avatarImageName completion:(nullable void (^)(BOOL, NSError * __nullable))completionBlock;
-(void) deleteAvatars;
-(void) deleteAttachedImages;

-(nullable NSDictionary *) getAllExistingAvatarsPreviews;
-(nullable NSArray <NSString *> *) getAllExistingAvatarsPreviewFileNames;
@end