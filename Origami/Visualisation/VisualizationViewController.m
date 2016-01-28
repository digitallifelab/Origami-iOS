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

@interface VisualizationViewController () <LGAlertViewDelegate>
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
@property (nonatomic, strong) NSMutableArray        *elementsArray;

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
        self.objectsToVisualize = [NSMutableArray arrayWithArray:array];
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
        
        NSArray *sortedObjects = [self getSortedObjects];
        
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
        _scrollView.contentSize = scrollViewSize;
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
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
        _elementView = [[OKVisualizationLayer alloc] init];
        
        BOOL firstElement = YES;
        
        for (NSArray *rowArray in sortedObjects) {
            
            for (VisualizableObject *obj in rowArray) {
                
                if (firstElement & (obj.rootElementId == 0)) {
                    firstElement = NO;
                    aPoint.y = scrollViewHeight - 50.f;
                } else if (obj.rootElementId == 0) {
                    aPoint.y = scrollViewHeight - 50.f;
                    aPoint.x = aPoint.x + indentX;
                }
                
                OKVisualizationLayer *view = [_elementView getElementView:obj at:CGPointMake(aPoint.x, aPoint.y)];
                view.elementId      = obj.elementId;
                view.rootElementId  = obj.rootElementId;
                
                // Add the drag gesture recognizer with default values.
                BFDragGestureRecognizer *holdDragRecognizer = [[BFDragGestureRecognizer alloc] init];
                [holdDragRecognizer addTarget:self action:@selector(dragRecognized:)];
                [view addGestureRecognizer:holdDragRecognizer];
                
                aPoint.y = aPoint.y - indentY;
                
                [_contentView addSubview:view];
                
            }
            
        }
        
    }
}

#pragma mark - Service methods

- (NSArray*)getSortedObjects
{
    
    NSArray *elementsHierarchy = [self getElementsSortHierarchy:self.objectsToVisualize];
    
    NSArray *sortedElements    = [self getSortedElementsInArrays:elementsHierarchy];
    
    return sortedElements;
    
}

- (NSArray *)getElementsSortHierarchy:(NSArray *)Data
{
    
    NSMutableDictionary *element = [NSMutableDictionary dictionary];
    [element setObject:[NSNumber numberWithInt:0] forKey:@"elementId"];
    
    self.elementsArray = [[NSMutableArray alloc] init];
    
    [self recursiveFunction:Data parentElement:element];
    
    return self.elementsArray;

}

- (void)recursiveFunction:(NSArray *)array parentElement:(id)parentElement
{
    
    NSArray *subElements = [self findSubElementsForElementID:[[parentElement valueForKey:@"elementId"] intValue] elementData:array];
    
    for (VisualizableObject *object in subElements) {
        
        [self.elementsArray addObject:object];

        [self recursiveFunction:array parentElement:object];
        
    }
    
}

- (NSArray *)findSubElementsForElementID:(int)elementID elementData:(NSArray *)elementData
{
    
    NSIndexSet *indexsForFilteredElements = [elementData indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        return (BOOL)([[obj valueForKey:@"rootElementId"] intValue] == elementID);
    }];
    
    return [elementData objectsAtIndexes:indexsForFilteredElements];
    
}

- (NSDictionary *)indexKeyedDictionaryFromArray:(NSArray *)array
{
    VisualizableObject *objectInstance;
    NSUInteger indexKey = 0U;

    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    for (objectInstance in array)

        [mutableDictionary setObject:objectInstance forKey:[NSNumber numberWithUnsignedInt:objectInstance.elementId]];
    indexKey++;

    return (NSDictionary *)mutableDictionary;
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

- (NSArray *)getSortedElementsInArrays:(NSArray *)elementsHierarchy
{
    
    // 1. create arrays: rootElement + subElements
    NSMutableArray *subRowsArray = [[NSMutableArray alloc] init];
    NSMutableArray *subElements  = [[NSMutableArray alloc] init];
    
    for (VisualizableObject *obj in elementsHierarchy) {
        
        if (obj.rootElementId == 0) {
            
            if ([subElements count] > 0) {
                [subRowsArray addObject:subElements];
                subElements = [[NSMutableArray alloc] initWithObjects:obj, nil];
            } else {
                [subElements addObject:obj];
            }
            
        } else if ([obj isEqual:[elementsHierarchy lastObject]]) {
            [subElements addObject:obj];
            [subRowsArray addObject:subElements];
        } else {
            [subElements addObject:obj];
        }
        
    }
    
    // 2. sort arrays: rootElement is first element in a row + subElements, which sort by changeDate
    NSArray *nonProcessedElements = [subRowsArray sortedArrayUsingComparator: ^(id obj1, id obj2) {
        if ([obj1 count] > [obj2 count]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([obj1 count] < [obj2 count]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    NSMutableArray *processedElements = [NSMutableArray array];
    
    for (NSArray *notSortedArray in nonProcessedElements) {
        
        NSArray *sortedArray = [notSortedArray sortedArrayUsingComparator:^NSComparisonResult(VisualizableObject *obj1, VisualizableObject *obj2) {
            
            if (obj1.rootElementId > 0 && obj2.rootElementId > 0)  {
                
                if ([obj1.changeDate compare:obj2.changeDate] == NSOrderedDescending) {
                    return (NSComparisonResult)NSOrderedAscending;
                } else if ([obj1.changeDate compare:obj2.changeDate] == NSOrderedAscending) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        [processedElements addObject:sortedArray];
        
    }
    
    return processedElements;
    
}


#pragma mark - BFDragGestureRecognizer

- (void)dragRecognized:(BFDragGestureRecognizer *)recognizer
{
    
    OKVisualizationLayer *view = (OKVisualizationLayer*)recognizer.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        NSArray *subviews = [view subviews];
        
        if ([subviews count] == 0) return;
        
        UILabel *label = subviews[0];
        
        UIColor *borderColor;
        if ([view.backgroundColor isEqual:[UIColor colorWithRed:1.f green:0.f blue:0.5 alpha:1.f]]) {
            borderColor = [UIColor colorWithRed:1.f green:0.f blue:0.5 alpha:1.f];
        } else {
            borderColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];
        }

        NSString *serviceElementText = [NSString stringWithFormat:@"%d/%d", view.rootElementId, view.elementId];
        
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:label.text
                                                            message:serviceElementText
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:@[@"Перейти к элементу в основной интерфейс"]
                                                  cancelButtonTitle:@"Отмена"
                                             destructiveButtonTitle:@""
                                                      actionHandler:nil
                                                      cancelHandler:nil
                                                 destructiveHandler:nil];
        
        alertView.pressedElementId = view.elementId;
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
        alertView.delegate = self;
        [alertView showAnimated:YES completionHandler:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateFailed) {
        
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView1
{
    return _contentView;
}


#pragma mark - LGAlertViewDelegate

- (void)alertView:(LGAlertView *)alertView buttonPressedWithTitle:(NSString *)title index:(NSUInteger)index
{
    
    if ([self.navigationController.viewControllers.firstObject isKindOfClass:[HomeVC class]])
    {
        HomeVC *rootVC = self.navigationController.viewControllers.firstObject;
        
        [rootVC presentNewSingleElementVC:alertView.pressedElementId];
    }

}

@end
