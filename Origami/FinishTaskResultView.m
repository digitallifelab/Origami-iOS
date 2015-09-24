//
//  FinishTaskResultView.m
//  Origami
//
//  Created by CloudCraft on 23.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

#import "FinishTaskResultView.h"

@implementation FinishTaskResultView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//+(instancetype)instance
//{
//    
//}

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"FinishTaskResultView" owner:self options:nil];
        self.view.layer.cornerRadius = 5.0;
        self.view.clipsToBounds = YES;
        [self addSubview:self.view];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"FinishTaskResultView" owner:self options:nil];
        //[self addSubview:self.view];
    }
    return self;
}
-(void) layoutSubviews
{
    [super layoutSubviews];
    [self.closeButton setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
}

-(void)setTint:(UIColor *)tintColor
{
    self.closeButton.tintColor = tintColor;
    self.goodButton.tintColor = tintColor;
    self.badButton.tintColor = tintColor;
}

-(void) setBackgroundColor:(UIColor *)backgroundColor
{
    self.view.backgroundColor = backgroundColor;
}

-(void) showAnimated:(BOOL) animated
{
    if (animated)
    {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        }];
    }
    else
    {
        self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    }
}

-(void) hideAnimated:(BOOL) animated
{
    if(animated)
    {
         __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.view.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [weakSelf removeFromSuperview];
        }];
    }
    else
    {
        [self removeFromSuperview];
    }
}

- (IBAction)cancelAction:(UIButton *)sender {
    [self.delegate finishTaskResultViewDidCancel:self];
}
- (IBAction)badAction:(UIButton *)sender {
    [self.delegate finishTaskResultViewDidPressBadButton:self];
}

- (IBAction)goodAction:(UIButton *)sender {
    [self.delegate finishTaskResultViewDidPressGoodButton:self];
}

@end
