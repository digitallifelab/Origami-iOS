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
@property (nonatomic, assign) NSInteger currentViewControllersCount;
@end

@implementation VisualizationViewController {
    CGPoint _startCenter;
    UIScrollView *_scrollView;
    UIView *_contentView;
    OKVisualizationLayer *_elementView;
}

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
    
    [self prepareMatrixViewAndShow];
}

-(void) setupRightNavigationButton
{
    
    if( self.currentViewControllersCount < 4)
    {

        // _scrollView
        // TODO: calculate Height and Width due in count objectsToVisualize. Default: 1000, 1000.
        CGFloat scrollViewHeight = 1000;
        CGFloat scrollViewWidth = 1000;
        CGSize scrollViewSize = CGSizeMake(scrollViewWidth, scrollViewHeight);
        CGRect rect = (CGRect){CGPointZero, scrollViewSize};
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
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
        
        CGPoint center = CGPointMake(scrollViewWidth / 2, scrollViewHeight / 2);
        
        // TODO: focus to sector 3
        // TODO: ??? _startCenter - look to the example project
        
        //_scrollView.contentOffset = CGPointMake(center.x - _scrollView.bounds.size.width / 2, center.y - _scrollView.bounds.size.height / 2);
        _scrollView.contentOffset = CGPointMake(0, 0);
        
        
        
        NSArray *sortedObjects = [objectsToVisualize sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
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

        //for (VisualizableObject *obj in sortedObjects) {
        //    NSLog(@"rootElementId = %d, elementID = %d", obj.rootElementId, obj.elementId);
        //}
        
        CGFloat xC = 0;
        CGFloat yC = 0;
        
        for (VisualizableObject *obj in sortedObjects) {
            
            _elementView = [[OKVisualizationLayer alloc] init];
            UIView *view = [_elementView getElementView:obj at:CGPointMake(xC, yC)];
            
            /*
            BOOL canPlace = NO;
            while (!canPlace) {
                
                
                // TODO: not randomPoint
                CGPoint randomPoint = CGPointMake(100 + random() % (int)(scrollViewWidth - 200),
                                                  100 + random() % (int)(scrollViewHeight - 200));
                
                
                randomRect = (CGRect){randomPoint, CGSizeMake(50, 50)};
                
                canPlace = YES;
                for (UIView *subview in _contentView.subviews) {
                    if (CGRectIntersectsRect(randomRect, subview.frame)) {
                        canPlace = NO;
                        break;
                    }
                }
            }*/
            
            
            [_contentView addSubview:view];
            
            xC = xC + 20;
            yC = yC + 20;
            
            
            
            // Add the drag gesture recognizer with default values.
            BFDragGestureRecognizer *holdDragRecognizer = [[BFDragGestureRecognizer alloc] init];
            [holdDragRecognizer addTarget:self action:@selector(dragRecognized:)];
            [view addGestureRecognizer:holdDragRecognizer];

            
            /* ***********
            // Use a fixed seed to always have the same color views.
            srandom(314159265);
            
            // Find a random position for the color view, that doesn't intersect other views.
            CGRect randomRect = CGRectZero;
            BOOL canPlace = NO;
            while (!canPlace) {

                
                // TODO: not randomPoint
                CGPoint randomPoint = CGPointMake(100 + random() % (int)(scrollViewWidth - 200),
                                                  100 + random() % (int)(scrollViewHeight - 200));
                
                
                randomRect = (CGRect){randomPoint, CGSizeMake(50, 50)};
                
                canPlace = YES;
                for (UIView *subview in _contentView.subviews) {
                    if (CGRectIntersectsRect(randomRect, subview.frame)) {
                        canPlace = NO;
                        break;
                    }
                }
            }
            
            UITextView *view = [[UITextView alloc] initWithFrame:randomRect];
            
            //view.text = [NSString stri obj.elementId;
            view.editable = NO;
            view.layer.cornerRadius = randomRect.size.width / 2;
            
            // Assign a random background color.
            CGFloat hue = (CGFloat)(random() % 256 / 256.0);  //  0.0 to 1.0
            CGFloat saturation = (CGFloat)((random() % 128 / 256.0) + 0.5);  //  0.5 to 1.0, away from white
            CGFloat brightness = (CGFloat)((random() % 128 / 256.0) + 0.5);  //  0.5 to 1.0, away from black
            UIColor *randomColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
            view.backgroundColor = randomColor;
            [_contentView addSubview:view];
            
            // Add the drag gesture recognizer with default values.
            BFDragGestureRecognizer *holdDragRecognizer = [[BFDragGestureRecognizer alloc] init];
            [holdDragRecognizer addTarget:self action:@selector(dragRecognized:)];
            [view addGestureRecognizer:holdDragRecognizer];
             
            */
             
         
        }

    }
}

-(void) prepareMatrixViewAndShow
{
    if (self.objectsToVisualize)
    {
       
        NSInteger objectsCount = self.objectsToVisualize.count;
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

-(void)subVClick:(PFButton*)sender{
    NSLog(@"%@",sender.titleLabel.text);
    NSInteger tagTapped = sender.elementIdTag;
    BOOL isStart=[sphereView isTimerStart];
    
    [sphereView timerStop];
    
    __weak typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:0.3 animations:^{
        sender.transform=CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            sender.transform=CGAffineTransformMakeScale(1, 1);
            if (isStart) {
                [sphereView timerStart];
            }
        }];
        [weakSelf showTappedElementByTag:tagTapped];
    }];
}



-(void)changePF:(UIButton*)sender{
    if ([sphereView isTimerStart]) {
        [sphereView timerStop];
    }
    else{
        [sphereView timerStart];
    }
}


-(void) showNextSelf:(UIBarButtonItem *)sender
{
    typeof(self) nextViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VisualizationVC"];
    nextViewController.objectsToVisualize = self.objectsToVisualize;
    [self.navigationController pushViewController:nextViewController animated:YES];
}


-(void) showTappedElementByTag:(NSInteger) elementButtonTag
{
    printf("tapped: %ld", (long)elementButtonTag);
    if ([self.navigationController.viewControllers.firstObject isKindOfClass:[HomeVC class]])
    {
        HomeVC *rootVC = self.navigationController.viewControllers.firstObject;
        
        [rootVC presentNewSingleElementVC:elementButtonTag];
    }
}

/*
#pragma mark - Navigation
*/
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
