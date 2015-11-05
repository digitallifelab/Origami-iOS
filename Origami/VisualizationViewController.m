//
//  VisualisationViewController.m
//  Origami
//
//  Created by CloudCraft on 04.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

#import "VisualizationViewController.h"
#import "VisualizableObject.h"
#ifdef SHEVCHENKO
#import "Shevchenko_network-Swift.h"
#else
#import "Origami_task_manager-Swift.h"
#endif
@interface VisualizationViewController ()

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

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSArray <VisualizableObject *> *objectsToVisualize = [[DataSource sharedInstance] getVisualizableContent];
    if (objectsToVisualize)
    {
        // do the stuff...
        //good luck :-)
    }
    
    
    //show stuff.
    
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
