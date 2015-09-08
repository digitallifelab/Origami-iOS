//
//  ElementOptionsConverter.h
//  Origami
//
//  Created by CloudCraft on 13.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, ElementOptions) // this enum type is currently uses all values but "ReservedValue"s. in future app implementations, theese reserved values are subjects to change to some vales that make sense.
{
    ElementOptionsNone = 0,
    ElementOptionsIdea = (1 << 2),
    ElementOptionsTask = (1 << 3),
    ElementOptionsDecision = (1 << 4),
    ElementOptionsReservedValue1 = (1 << 5),
    ElementOptionsReservedValue2 = (1 << 6)
};


@interface ElementOptionsConverter : NSObject

-(NSInteger) toggleOptionChange:(NSInteger)inputOptions selectedOption:(NSInteger)option;

-(BOOL)isOptionEnabled:(ElementOptions)option forCurrentOptions:(NSInteger)currentOptions;

@end
