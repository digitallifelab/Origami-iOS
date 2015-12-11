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
#import "PFButton.h"
#endif

@interface VisualizationViewController ()
{
    ZYQSphereView *sphereView;
    NSTimer *timer;
}
@property (nonatomic, assign) NSInteger currentViewControllersCount;
@end

@implementation VisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidDisappear:(BOOL)animated
{
    [sphereView timerStop];
    [sphereView removeFromSuperview];
    sphereView = nil;
    
    //[self.objectsToVisualize removeAllObjects];
    //self.objectsToVisualize = nil;
    [super viewDidDisappear:animated];
    
}

-(void) viewWillAppear:(BOOL)animated
{
    self.currentViewControllersCount = self.navigationController.viewControllers.count;
    [self setupRightNavigationButton];
}

-(void) viewDidAppear:(BOOL)animated
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
            subV.frame = (showsCircleButtons) ? CGRectMake(0, 0, 30, 30) : CGRectMake(0, 0, 60, 30) ;
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
            subV.titleLabel.lineBreakMode = NSLineBreakByClipping;
            subV.titleLabel.textColor = [UIColor whiteColor];
           
            
            NSString *currentTitle = currentObject.title;
            if (currentTitle.length > 6)
            {
                currentTitle = [currentTitle substringToIndex:6];
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
        
            [subV addTarget:self action:@selector(subVClick:) forControlEvents:UIControlEventTouchUpInside];
            
            subV.elementIdTag = currentObject.elementId;
            printf("tag: %ld",(long)subV.tag);
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
