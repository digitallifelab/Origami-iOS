//
//  VisualisationViewController.m
//  Origami
//
//  Created by CloudCraft on 04.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import "VisualizationViewController.h"

#ifdef SHEVCHENKO
#import "Shevchenko_network-Swift.h"
#else
#import "BFDragGestureRecognizer.h"
#import "LGAlertView.h"
#import "OKVisualizationLayer.h"
#import "Origami_task_manager-Swift.h"
#import "ZYQSphereView.h"
#endif

@interface VisualizationViewController ()
{
    ZYQSphereView *sphereView;
    NSTimer *timer;
}

@property (nonatomic, assign) NSInteger  currentViewControllersCount;
@property (nonatomic, strong, nullable)  NSMutableArray <VisualizableObject *> *objectsToVisualize;
@property (nonatomic, strong) UIScrollView          *scrollView;
@property (nonatomic, assign) CGPoint               startCenter;
@property (nonatomic, strong) UIView                *contentView;
@property (nonatomic, strong) OKVisualizationLayer  *elementView;

@end

@implementation VisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.objectsToVisualize)
    {
        NSArray * array = [[DataSource sharedInstance] getVisualizableContent];
        self.objectsToVisualize =  [NSMutableArray arrayWithArray:array];
    }
    
    [self prepareElementsViewAndShow];
}

-(void) prepareElementsViewAndShow
{
    
    if( self.currentViewControllersCount < 4)
    {

        for (UIView *view in self.scrollView.subviews) {
            [view removeFromSuperview];
        }
        
        // TODO: 02.2 - сделал корректное распределение объектов в массивы: родитель -  подчиненные элементы
        NSArray *sortedObjects = [self getSortedObjects];
        
        // TODO: 03.3 доработал расчет размера скроллвью: исправил ошибки
        CGFloat indentX = 175.f;
        CGFloat indentY = 60.f;
        
        CGFloat countRows             = [sortedObjects count];
        CGFloat maxCountElementsInRow = [self getMaxCountElementsInRow:sortedObjects];
        
        CGFloat scrollViewHeight = 50.f + maxCountElementsInRow * indentY;
        CGFloat scrollViewWidth  = 50.f + (countRows * indentX);
        
        CGSize scrollViewSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
        CGRect rect = (CGRect){CGPointZero, scrollViewSize};
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.backgroundColor = [UIColor colorWithRed: 33.0/255.0 green: 150.0/255.0 blue: 243.0/255.0 alpha: 1.0];
        //kDayCellBackgroundColor;//[UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];//[UIColor colorWithWhite:0.9 alpha:1.f];
        _scrollView.contentSize = scrollViewSize;
        _scrollView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
        _scrollView.minimumZoomScale = 1;
        _scrollView.maximumZoomScale = 3;
        _scrollView.delegate = self;
        UIEdgeInsets indicatorInsets = _scrollView.scrollIndicatorInsets;
        indicatorInsets.bottom = _scrollView.contentInset.bottom;
        _scrollView.scrollIndicatorInsets = indicatorInsets;
        [self.view insertSubview:_scrollView atIndex:0];
        
        _contentView = [[UIView alloc] initWithFrame:rect];
        [_scrollView addSubview:_contentView];
        
        _scrollView.contentOffset = CGPointMake(0.f, scrollViewHeight - 400);
        
        CGPoint aPoint = CGPointMake(75.f, scrollViewHeight - 50.f);
        
        for (NSArray *rowArray in sortedObjects) {
            
            for (VisualizableObject *obj in rowArray) {
                
                _elementView = [[OKVisualizationLayer alloc] init];
                UIView *view = [_elementView getElementView:obj at:CGPointMake(aPoint.x, aPoint.y)];
                
                [_contentView addSubview:view];
                
                // Add the drag gesture recognizer with default values.
                BFDragGestureRecognizer *holdDragRecognizer = [[BFDragGestureRecognizer alloc] init];
                [holdDragRecognizer addTarget:self action:@selector(dragRecognized:)];
                [view addGestureRecognizer:holdDragRecognizer];
                
                aPoint.y = aPoint.y - indentY;
                
            }
            
            // FIX:
            if ([rowArray isEqual:[sortedObjects lastObject]]) {
                aPoint.y = scrollViewHeight - 50.f;
                //aPoint.x = aPoint.x + indentX;
            } else {
                aPoint.y = scrollViewHeight - 50.f;
                aPoint.x = aPoint.x + indentX;
            }
            
        }

    }
}

#pragma mark - Service methods

- (NSArray*)getSortedObjects
{
    
    NSArray *sortedObjects = [self.objectsToVisualize sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSInteger firstRootId  = [(VisualizableObject*)obj1 rootElementId];
        NSInteger secondRootId = [(VisualizableObject*)obj2 rootElementId];
        
        NSInteger firstElementId  = [(VisualizableObject*)obj1 elementId];
        NSInteger secondElementId = [(VisualizableObject*)obj2 elementId];
        
        if ( firstRootId < secondRootId & firstElementId < secondElementId ) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if ( firstRootId > secondRootId & firstElementId > secondElementId ) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
        
    }];
    
    
    CGFloat countRootElements = 0;
    
    for (VisualizableObject *obj in sortedObjects) {
        //NSLog(@"index = %d, rootElementId = %d, elementID = %d", [sortedObjects indexOfObject:obj], obj.rootElementId, obj.elementId);
        if (obj.rootElementId == 0) {
            countRootElements++;
        }
    }
    
    CGFloat countElementsWithoutRootElements = sortedObjects.count - countRootElements;
    

    NSMutableArray *rootElementsArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < countRootElements; i++) {
        
        NSMutableArray *subArray = [[NSMutableArray alloc] init];
        
        for (int j = countElementsWithoutRootElements; j > 0; j--) {
            
            // add a root element
            if (j == countElementsWithoutRootElements) {
                [subArray addObject:[sortedObjects objectAtIndex:i]];
            }
            
            // add elements
            [subArray addObject:[sortedObjects objectAtIndex:j]];
            
        }
        
        [rootElementsArray addObject:subArray];
        
    }
    
    return rootElementsArray;
    
}

- (CGFloat)getMaxCountElementsInRow:(NSArray *)sortedObjects
{
    CGFloat result = 0;
    for (NSArray *obj in sortedObjects) {
        if (obj.count > result) {
            result = obj.count;
        }
    }
    
    return result;
}


#pragma mark - BFDragGestureRecognizer

- (void)dragRecognized:(BFDragGestureRecognizer *)recognizer {
    
    UIView *view = recognizer.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        NSArray *subviews = [view subviews];
        
        if ([subviews count] == 0) return;
        
        UILabel *label = subviews[0];
        UILabel *serviceLabel = subviews[1];
        
        UIColor *borderColor;
        if ([view.backgroundColor isEqual:[UIColor colorWithRed:1.f green:0.f blue:0.5 alpha:1.f]]) {
            borderColor = [UIColor colorWithRed:1.f green:0.f blue:0.5 alpha:1.f];
        } else {
            borderColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        }

        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:[label text]
                                                            message:[serviceLabel text]
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:@[@"Перейти к элементу в основной интерфейс"]
                                                  cancelButtonTitle:@"Отмена"
                                             destructiveButtonTitle:@""
                                                      actionHandler:nil
                                                      cancelHandler:nil
                                                 destructiveHandler:nil];
        
        alertView.coverColor = [UIColor colorWithWhite:1.f alpha:0.9];
        alertView.layerShadowColor = [UIColor colorWithWhite:0.f alpha:0.3];
        alertView.layerShadowRadius = 4.f;
        alertView.layerCornerRadius = 0.f;
        alertView.layerBorderWidth = 2.f;
        alertView.layerBorderColor = borderColor;
        alertView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.7];
        alertView.width = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        alertView.titleTextAlignment = NSTextAlignmentLeft;
        alertView.messageTextAlignment = NSTextAlignmentLeft;
        alertView.oneRowOneButton = YES;
        alertView.buttonsTextAlignment = NSTextAlignmentRight;
        alertView.cancelButtonTextAlignment = NSTextAlignmentRight;
        alertView.destructiveButtonTextAlignment = NSTextAlignmentRight;
        [alertView showAnimated:YES completionHandler:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateFailed) {
        
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView1 {
    // TODO: if zoom == maxSize then titleColour = white
    // else titleColour = clear
    return _contentView;
}


@end
