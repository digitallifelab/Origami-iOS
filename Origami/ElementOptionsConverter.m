//
//  ElementOptionsConverter.m
//  Origami
//
//  Created by CloudCraft on 13.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import "ElementOptionsConverter.h"

@implementation ElementOptionsConverter

-(NSInteger) toggleOptionChange:(NSInteger)inputOptions selectedOption:(NSInteger)option
{
    NSInteger currentOptions = inputOptions;
    switch (option)
    {
        case 0:
            break;
        case 1:
            if (currentOptions & ElementOptionsIdea)
            {
                currentOptions  = currentOptions & ~ElementOptionsIdea;
            }
            else
            {
                currentOptions = currentOptions | ElementOptionsIdea;
            }
            break;
        case 2:
        {
            if (currentOptions & ElementOptionsTask)
            {
                currentOptions = currentOptions & ~ElementOptionsTask;
            }
            else
            {
                currentOptions = currentOptions | ElementOptionsTask;
            }
        }
            break;
        case 3:
        {
            if (currentOptions & ElementOptionsDecision)
            {
                currentOptions = currentOptions & ~ElementOptionsDecision;
            }
            else
            {
                currentOptions = currentOptions | ElementOptionsDecision;
            }
        }
            break;
        case 4:
        {
            if (currentOptions & ElementOptionsReservedValue1)
            {
                currentOptions = currentOptions & ~ElementOptionsReservedValue1;
            }
            else
            {
                currentOptions = currentOptions | ElementOptionsReservedValue1;
            }
        }
            break;
        default:
            break;
    }
    
    return currentOptions;
}

-(BOOL)isOptionEnabled:(ElementOptions)option forCurrentOptions:(NSInteger)currentOptions
{
//#ifdef DEBUG
//    NSLog(@" -> Checking for option %@", [self debugAskedOption:option]);
//#endif
    if ((currentOptions & option) == option)
        return YES;
    
    return NO;
}

- (nonnull NSString *)debugAskedOption:(ElementOptions)option
{
    switch (option) {
        case ElementOptionsNone :
            return @"ElementOptions.None";
        case ElementOptionsIdea :
            return @"ElementOptions.Idea";
        case ElementOptionsTask:
            return @"ElementOptions.Task";
        case ElementOptionsDecision :
            return @"ElementOptions.Decision";
        case ElementOptionsReservedValue1:
            return @"ElementOptions.ReservedValue1";
        case ElementOptionsReservedValue2:
            return @"ElementOptions.ReservedValue2";
        default:
            return @"Warning! : illegal Type";
    }
}

@end
