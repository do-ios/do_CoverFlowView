//
//  do_CoverFlowView_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_CoverFlowView_IView.h"
#import "do_CoverFlowView_UIModel.h"
#import "doIUIModuleView.h"

@interface do_CoverFlowView_UIView : UICollectionView<do_CoverFlowView_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_CoverFlowView_UIModel *_model;
}

@end
