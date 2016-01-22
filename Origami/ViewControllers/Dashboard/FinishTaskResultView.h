//
//  FinishTaskResultView.h
//  Origami
//
//  Created by CloudCraft on 23.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FinishTaskResultView;

@protocol FinishTaskResultViewDelegate <NSObject>

-(void) finishTaskResultViewDidPressGoodButton:(FinishTaskResultView *)resultView;
-(void) finishTaskResultViewDidPressBadButton:(FinishTaskResultView *)resultView;
-(void) finishTaskResultViewDidCancel:(FinishTaskResultView *)resultView;
-(void) finishTaskResultViewDidPressCancellTaskButton:(FinishTaskResultView *)resultView;

@end


@interface FinishTaskResultView : UIView

@property (nonatomic, weak) IBOutlet UIView *view;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIButton *cencelTaskButton;
@property (nonatomic, weak) IBOutlet UIButton *badButton;
@property (nonatomic, weak) IBOutlet UIButton *goodButton;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) id <FinishTaskResultViewDelegate> delegate;
-(void) showAnimated:(BOOL) animated;
-(void) hideAnimated:(BOOL) animated;
//+(instancetype) instance;
@end
