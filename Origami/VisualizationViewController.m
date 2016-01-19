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
#import "ZYQSphereView.h"
#import "Origami_task_manager-Swift.h"
#import "OKVisualizationLayer.h"
#import "BFDragGestureRecognizer.h"
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
        CGFloat indentX = 150.f;
        CGFloat indentY = 60.f;
        CGFloat maxDiam = 100.f;
        
        CGFloat countRows             = [sortedObjects count];
        CGFloat maxCountElementsInRow = [self getMaxCountElementsInRow:sortedObjects];
        
        CGFloat scrollViewHeight = 100.f + maxCountElementsInRow * maxDiam * 0.75;
        CGFloat scrollViewWidth  = 200.f + (countRows * maxDiam);
        
        CGSize scrollViewSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
        CGRect rect = (CGRect){CGPointZero, scrollViewSize};
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.f];//[UIColor lightGrayColor];
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
            
            // subArrays
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

-(void) prepareMatrixViewAndShow
{
    if (self.objectsToVisualize)
    {
       
        //NSInteger objectsCount = self.objectsToVisualize.count;
        BOOL showsBackgroundColor = YES;
        BOOL showsCircleButtons = NO;
        if (self.currentViewControllersCount == 3)
        {
            showsCircleButtons = YES;
        }
        
        if (self.currentViewControllersCount == 4)
        {
            showsBackgroundColor = NO;
        }
    
    //show stuff.

    }
    
}

//-(void)subVClick:(PFButton*)sender{
//    NSLog(@"%@",sender.titleLabel.text);
//    NSInteger tagTapped = sender.elementIdTag;
//    BOOL isStart=[sphereView isTimerStart];
//    
//    [sphereView timerStop];
//    
//    __weak typeof(self) weakSelf = self;
//    
//    [UIView animateWithDuration:0.3 animations:^{
//        sender.transform=CGAffineTransformMakeScale(1.5, 1.5);
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.2 animations:^{
//            sender.transform=CGAffineTransformMakeScale(1, 1);
//            if (isStart) {
//                [sphereView timerStart];
//            }
//        }];
//        [weakSelf showTappedElementByTag:tagTapped];
//    }];
//}



//-(void)changePF:(UIButton*)sender{
//    if ([sphereView isTimerStart]) {
//        [sphereView timerStop];
//    }
//    else{
//        [sphereView timerStart];
//    }
//}


//-(void) showNextSelf:(UIBarButtonItem *)sender
//{
//    typeof(self) nextViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VisualizationVC"];
//    nextViewController.objectsToVisualize = self.objectsToVisualize;
//    [self.navigationController pushViewController:nextViewController animated:YES];
//}


//-(void) showTappedElementByTag:(NSInteger) elementButtonTag
//{
//    printf("tapped: %ld", (long)elementButtonTag);
//    if ([self.navigationController.viewControllers.firstObject isKindOfClass:[HomeVC class]])
//    {
//        HomeVC *rootVC = self.navigationController.viewControllers.firstObject;
//        
//        [rootVC presentNewSingleElementVC:elementButtonTag];
//    }
//}

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
        // When the gesture starts, remember the current position, and animate the it.
        _startCenter = view.center;
        [view.superview bringSubviewToFront:view];
        [UIView animateWithDuration:0.2 animations:^{
            view.transform = CGAffineTransformMakeScale(1.2, 1.2);
            view.alpha = 0.7;
        }];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // During the gesture, we just add the gesture's translation to the saved original position.
        // The translation will account for the changes in contentOffset caused by auto-scrolling.
        CGPoint translation = [recognizer translationInView:_contentView];
        CGPoint center = CGPointMake(_startCenter.x + translation.x, _startCenter.y + translation.y);
        view.center = center;
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.2 animations:^{
            view.transform = CGAffineTransformIdentity;
            view.alpha = 1.0;
        }];
    } else if (recognizer.state == UIGestureRecognizerStateFailed) {
        
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView1 {
    // TODO: if zoom == maxSize then titleColour = white
    // else titleColour = clear
    return _contentView;
}


@end
