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
#import "PFButton.h"
#endif



@interface VisualizationViewController ()
{
    ZYQSphereView *sphereView;
    NSTimer *timer;
}
@property (nonatomic, assign) NSInteger currentViewControllersCount;
@property (nonatomic, strong, nullable)  NSMutableArray <VisualizableObject *> *objectsToVisualize;
@end

@implementation VisualizationViewController {
    CGPoint _startCenter;
    UIScrollView *_scrollView;
    UIView *_contentView;
    OKVisualizationLayer *_elementView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupRightNavigationButton];
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
    self.currentViewControllersCount = self.navigationController.viewControllers.count;
    
    if( self.currentViewControllersCount < 4)
    {
        SEL nextViewControllerSelector = @selector(showNextSelf:);
        
        UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:nextViewControllerSelector];
        self.navigationItem.rightBarButtonItem = rightButtonItem;
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
        
        self.view.backgroundColor = [UIColor blackColor];
        UIColor *buttonBackroundColor =[UIColor colorWithRed:33.0/255.0 green:150.0/255.0 blue:243.0/255.0 alpha:1.0];
        UIColor *signalRedColor = [UIColor colorWithRed:233.0/255.0 green:30.0/255.0 blue:83.0/255.0 alpha:1.0];
        UIColor *whiteTextColor = [UIColor whiteColor];
        
        CGFloat minimumDimension = MIN(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) * 0.9;
        UIFont *segoeFont = [UIFont fontWithName:@"Segoe UI" size:13.0];
        sphereView = [[ZYQSphereView alloc] initWithFrame:CGRectMake(10, 60, minimumDimension, minimumDimension)];
        sphereView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        NSMutableArray *views = [[NSMutableArray alloc] init];
        for (int i = 0; i < objectsCount; i++)
        {
            VisualizableObject *currentObject = self.objectsToVisualize[i];
            
            PFButton *subV = [PFButton buttonWithType:UIButtonTypeSystem];
            subV.frame = (showsCircleButtons) ? CGRectMake(0, 0, 30, 30) : CGRectMake(0, 0, 80, 60) ;
            subV.titleLabel.numberOfLines = 0;
            subV.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            subV.titleLabel.preferredMaxLayoutWidth = 60.0;
            subV.titleLabel.adjustsFontSizeToFitWidth = YES;
            //subV.titleLabel.backgroundColor = [UIColor yellowColor];
            
            if (showsCircleButtons)
            {
                subV.layer.cornerRadius = 15.0;
                subV.layer.masksToBounds = YES;
            }
            else
            {
                subV.layer.masksToBounds=YES;
                subV.layer.cornerRadius=3;
            }
            
            NSString *currentTitle = currentObject.title;
            if (currentTitle.length > 20)
            {
                currentTitle = [currentTitle substringToIndex:20];
            }
            
            NSAttributedString *textToSet;
            
            if (showsBackgroundColor)
            {
                subV.backgroundColor = (currentObject.isSignal) ? signalRedColor : buttonBackroundColor;
                if (!showsCircleButtons)
                {
                    textToSet = [[NSAttributedString alloc] initWithString:currentTitle.uppercaseString attributes:@{NSForegroundColorAttributeName: whiteTextColor, NSFontAttributeName:segoeFont}];
                    [subV setAttributedTitle:textToSet forState:UIControlStateNormal];
                }
            }
            else
            {
                subV.backgroundColor = [UIColor clearColor];
                if (!showsCircleButtons)
                {
                    UIColor *currentTextColor = (currentObject.isSignal) ? signalRedColor : whiteTextColor;
                    textToSet = [[NSAttributedString alloc] initWithString:currentTitle.uppercaseString attributes:@{NSForegroundColorAttributeName: currentTextColor, NSFontAttributeName:segoeFont}];
                    [subV setAttributedTitle:textToSet forState:UIControlStateNormal];
                }
            }
            
            //[subV sizeToFit];
            [subV addTarget:self action:@selector(subVClick:) forControlEvents:UIControlEventTouchUpInside];
            
            subV.elementIdTag = currentObject.elementId;
            //printf("tag: %ld",(long)subV.tag);
            [views addObject:subV];
            //[subV release];
        }
        
        [sphereView setItems:views];
        
        sphereView.isPanTimerStart=YES;
        //[views release];
        
        [self.view addSubview:sphereView];
        [sphereView timerStart];
        
        UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame=CGRectMake((self.view.frame.size.width-120)/2, self.view.frame.size.height-60, 120, 30);
        [self.view addSubview:btn];
        btn.backgroundColor=[UIColor whiteColor];
        btn.layer.borderWidth=1;
        btn.layer.borderColor=[[UIColor orangeColor] CGColor];
        [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [btn setTitle:@"start/stop" forState:UIControlStateNormal];
        btn.selected=NO;
        [btn addTarget:self action:@selector(changePF:) forControlEvents:UIControlEventTouchUpInside];
    }
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
