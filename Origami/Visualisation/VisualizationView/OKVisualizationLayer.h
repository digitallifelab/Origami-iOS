//
//  OKVisualizationLayer.h
//  Origami
//
//  Created by Oleg Kovalyok on 24.12.15, Th.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisualizableObject.h"

@interface OKVisualizationLayer : UIView

@property (nonatomic, strong) UIColor *elementColor;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) NSInteger elementId;
@property (nonatomic, assign) NSInteger rootElementId;


// origami
- (OKVisualizationLayer *)getElementView:(VisualizableObject *)obj at:(CGPoint)point;

@end
