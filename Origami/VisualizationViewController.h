//
//  VisualisationViewController.h
//  Origami
//
//  Created by CloudCraft on 04.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisualizableObject.h"
@interface VisualizationViewController : UIViewController
@property (nonatomic, strong) NSMutableArray <VisualizableObject *> *objectsToVisualize;
@end
