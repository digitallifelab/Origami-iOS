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
        self.elementColor    = [UIColor blueColor];
        self.lineColor       = [UIColor yellowColor];
        self.clipsToBounds   = YES;
        
        self.userInteractionEnabled = YES;
        isContainView = YES;
        LastBezierPath = [UIBezierPath bezierPath];
    }
    return self;
}


- (UIView *)getElementView:(VisualizableObject *)obj at:(CGPoint)point
{
    
    CGFloat width = arc4random()%50 + 30;
    
    UIView *element = [[UIView alloc] initWithFrame:CGRectMake(point.x - width/2, point.y-width/2, width, width)];
    element.alpha = 0.8;
    element.backgroundColor    = self.elementColor;
    element.layer.borderColor  = self.lineColor.CGColor;
    element.layer.borderWidth  = 4;
    element.layer.cornerRadius = element.layer.bounds.size.width / 2;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, width)];
    title.text = [NSString stringWithFormat:@"%@", obj.title];
    title.textColor = [UIColor clearColor];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont systemFontOfSize:14];
    title.textAlignment = NSTextAlignmentCenter;
    
    [element addSubview:title];
    
    return element;
}


@end
