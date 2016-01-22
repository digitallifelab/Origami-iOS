//
//  OKVisualizationLayer.m
//  Origami
//
//  Created by Oleg Kovalyok on 24.12.15, Th.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import "OKVisualizationLayer.h"
#import <QuartzCore/QuartzCore.h>
#import "BFDragGestureRecognizer.h"


@interface OKVisualizationLayer () {
    CGPoint lastElement;
    UIBezierPath *LastBezierPath;
    BOOL isContainView;
}

@end


@implementation OKVisualizationLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.elementColor    = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        self.lineColor       = [UIColor whiteColor];
        self.clipsToBounds   = YES;
        
        self.userInteractionEnabled = YES;
        isContainView = YES;
        LastBezierPath = [UIBezierPath bezierPath];
    }
    return self;
}


- (UIView *)getElementView:(VisualizableObject *)obj at:(CGPoint)point
{
    
    CGFloat width = [self getWidthElement:obj.messagesCount];
    UIView *element = [[UIView alloc] initWithFrame:CGRectMake(point.x - width/2, point.y-width/2, width, width)];
    element.alpha = 0.8;
    
    if (obj.isSignal) {
        element.backgroundColor = [UIColor colorWithRed:1.f green:0.f blue:0.5 alpha:1.f];
    } else {
        element.backgroundColor = self.elementColor;
    }
    
    element.layer.borderColor  = self.lineColor.CGColor;
    element.layer.borderWidth  = 2;
    element.layer.cornerRadius = element.layer.bounds.size.width/2;
    
    element.layer.shadowColor  = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.f].CGColor;
    element.layer.shadowRadius = 2.f;
    element.layer.shadowOffset = CGSizeMake(2.f, 2.f);    
    element.layer.shadowOpacity = 0.5;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(element.layer.bounds.size.width/2, 0, 150, width)];
    title.text = [NSString stringWithFormat:@"%@", obj.title];
    title.font = [UIFont systemFontOfSize:14.f];
    title.textColor = [UIColor blackColor];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = NSTextAlignmentNatural;
    [element addSubview:title];
    
    UILabel *serviceElement = [[UILabel alloc] initWithFrame:CGRectMake(element.layer.bounds.size.width/2, 0, 150, width)];
    serviceElement.text = [NSString stringWithFormat:@"%d/%d; %@", obj.rootElementId, obj.elementId, obj.details];
    NSLog(@"%@", serviceElement.text);
    serviceElement.textColor = [UIColor clearColor];
    serviceElement.backgroundColor = [UIColor clearColor];
    [element addSubview:serviceElement];
    
    return element;
    
}


- (CGFloat)getWidthElement:(NSInteger)messagesCount {
    
    CGFloat defaultWidth = 50;
    CGFloat addWidth = 0;
    
    if (messagesCount > 0 & messagesCount < 10) {
        addWidth = 5 * messagesCount;
    } else if (messagesCount > 10) {
        addWidth = 50;
    }
    
    return defaultWidth + addWidth;
    
}


@end
