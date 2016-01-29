//
//  VisualizableObject.h
//  Origami
//
//  Created by CloudCraft on 04.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@interface VisualizableObject : NSObject

//element info
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *details;
@property (nonatomic, assign) NSInteger elementId;
@property (nonatomic, assign) NSInteger rootElementId;
@property (nonatomic, assign) BOOL isFavourite;
@property (nonatomic, assign) BOOL isSignal;

//creator or changer info
@property (nonatomic, strong, nullable) UIImage *avatarImage;
@property (nonatomic, strong, nullable) NSString *displayName;

@property (nonatomic, strong, nullable) NSDate *changeDate;
@property (nonatomic) NSInteger messagesCount;

@end
