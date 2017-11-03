//
//  do_CoverFlowView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_CoverFlowView_IView <NSObject>

@required
//属性方法
- (void)change_index:(NSString *)newValue;
- (void)change_looping:(NSString *)newValue;
- (void)change_spacing:(NSString *)newValue;
- (void)change_templates:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;


@end