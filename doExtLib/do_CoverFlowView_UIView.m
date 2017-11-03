//
//  do_CoverFlowView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_CoverFlowView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doCoverFlowViewLayout.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doIUIModuleFactory.h"
#import "doTextHelper.h"
#import "doIOHelper.h"
#import "doIPage.h"

#define LoopMaxCount 100

@interface do_CoverFlowView_UIView()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@end

static NSString *const CoverID = @"CoverFlowID";

@implementation do_CoverFlowView_UIView
{
    doCoverFlowViewLayout *flowLayout;
    id<doIListData> _dataArrays;
    NSMutableArray *_cellTemplatesArray;
    UIView *cellView;
    
    NSMutableArray * _indexCache;
    
    BOOL isLoop;
    int spcan;
    NSIndexPath *currentIndexPath;
    
    BOOL _isValidateTemplate;
}
-(instancetype) init
{
    flowLayout = [[doCoverFlowViewLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:flowLayout];
    return self;
}

#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    self.delegate = self;
    self.dataSource = self;
    [self registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:CoverID];
    self.showsHorizontalScrollIndicator = NO;
    [self setBackgroundColor:[UIColor clearColor]];
    _cellTemplatesArray = [NSMutableArray array];
    _indexCache = [NSMutableArray array];
    NSString *defSpan = [(doUIModule *)_model GetProperty:@"spacing"].DefaultValue;
    spcan = [defSpan floatValue] * _model.XZoom;//默认值
    flowLayout.minimumLineSpacing = spcan;
    self.scrollsToTop = NO;
    _isValidateTemplate = YES;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    self.delegate = nil;
    self.dataSource = nil;
    flowLayout = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_index:(NSString *)newValue
{
    //自己的代码实现
    @try {
        NSInteger index = [newValue integerValue];
        if (index >= [_dataArrays GetCount]) {
            index = [_dataArrays GetCount] - 1;
        }
        if(index < 0)
        {
            index = 0;
        }
        if ([self numberOfItemsInSection:0]==0) {
            return;
        }
        if (isLoop) {
            index = index % [_dataArrays GetCount];
            if (currentIndexPath) {
                int count = (int)(currentIndexPath.row - (LoopMaxCount / 2 *[_dataArrays GetCount]));
                if (count >0) {
                    int mod = count % [_dataArrays GetCount];
                    if (mod > index) {
                        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(currentIndexPath.row - (mod - index)) inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                        currentIndexPath = [NSIndexPath indexPathForRow:(currentIndexPath.row - (mod - index)) inSection:0];
                    }
                    else
                    {
                        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(currentIndexPath.row + (index - mod)) inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                        currentIndexPath = [NSIndexPath indexPathForRow:(currentIndexPath.row + (index - mod)) inSection:0];
                    }
                }
                else
                {
                    int mod = currentIndexPath.row % [_dataArrays GetCount];
                    if (mod > index) {
                        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(currentIndexPath.row - (mod - index)) inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                        currentIndexPath = [NSIndexPath indexPathForRow:(currentIndexPath.row - (mod - index)) inSection:0];
                    }
                    else
                    {
                        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(currentIndexPath.row + (index - mod)) inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                        currentIndexPath = [NSIndexPath indexPathForRow:(currentIndexPath.row + (index - mod)) inSection:0];
                        
                    }
                }
            }
        }
        else
        {
            [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
        [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)index]];
        doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
        [invokeResult SetResultText:[NSString stringWithFormat:@"%ld",(long)index]];
        [_model.EventCenter FireEvent:@"indexChanged" :invokeResult];
    }
    @catch (NSException *exception) {//等待view初始化加载完毕
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Do the expensive work on the background
            NSInteger index = [newValue integerValue];
            [NSThread sleepForTimeInterval:1.0f];
            if ([_dataArrays GetCount] == 0) {
                return ;
            }
            if (index >= [_dataArrays GetCount]) {
                index = [_dataArrays GetCount] - 1;
            }
            if(index < 0)
            {
                index = 0;
            }
            NSLog(@"loop2 %d",isLoop);
            doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
            [invokeResult SetResultText:[NSString stringWithFormat:@"%ld",(long)index]];
            [_model.EventCenter FireEvent:@"indexChanged" :invokeResult];
            // All UI related operations must be performed on the main thread!
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isLoop) {
                    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(index + LoopMaxCount / 2 *[_dataArrays GetCount]) inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                }
                else
                {
                    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                }
                [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)index]];
                [flowLayout invalidateLayout];
            });
        });
    }
}
- (void)change_looping:(NSString *)newValue
{
    //自己的代码实现
    isLoop = [[doTextHelper Instance] StrToBool:newValue :NO];
    if ([_dataArrays GetCount]==0 || !_dataArrays) {
        return;
    }
    if (isLoop) {
        @try {
            [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:LoopMaxCount / 2 * [_dataArrays GetCount] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        @catch (NSException *exception) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                // Do the expensive work on the background
                [NSThread sleepForTimeInterval:1.0f];
                dispatch_async(dispatch_get_main_queue(), ^{\
                    // Replace the view containing the activity indicator with the view of your model.
                    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:LoopMaxCount / 2 * [_dataArrays GetCount] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];                });
            });
        }
    }
}
- (void)change_spacing:(NSString *)newValue
{
    //自己的代码实现
    spcan = [newValue floatValue] * _model.XZoom;
    flowLayout.minimumLineSpacing = spcan;
    [self reloadData];
}
- (void)change_templates:(NSString *)newValue
{
    //自己的代码实现
    [_cellTemplatesArray removeAllObjects];
    [_cellTemplatesArray addObjectsFromArray:[newValue componentsSeparatedByString:@","]];
    
    BOOL isValidate = YES;
    if (_cellTemplatesArray.count==0) {
        _isValidateTemplate = NO;
        NSString *reason = [NSString stringWithFormat:@"模板为空"];
        NSException *ex = [[NSException alloc]initWithName:@"do_CoverFlowView" reason:reason userInfo:nil];
        [[doServiceContainer Instance].LogEngine WriteError:ex :@"模板错误"] ;
        isValidate = NO;
    }else{
        for(NSString *template in _cellTemplatesArray){
            NSString * imagePath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :template];
            if(![doIOHelper ExistFile:imagePath]){
                _isValidateTemplate = NO;
                NSString *reason = [NSString stringWithFormat:@"模板%@不存在",template];
                NSException *ex = [[NSException alloc]initWithName:@"do_CoverFlowView" reason:reason userInfo:nil];
                [[doServiceContainer Instance].LogEngine WriteError:ex :@"模板错误"] ;
                isValidate = NO;
            }
        }
    }
    
    _isValidateTemplate = isValidate;
}

#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doGridView" format:@"未指定相关的gridview data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doGridView" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArrays!= bindingModule)
                _dataArrays = bindingModule;
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
    }
}
- (void)refreshItems:(NSArray *)parms
{
    [self reloadData];
    if (_indexCache)[_indexCache removeAllObjects];
    for (int i = 0; i < LoopMaxCount; i ++) {
        for (int j = 0; j < [_dataArrays GetCount]; j ++) {
            [_indexCache addObject:@(j)];
        }
    }
    currentIndexPath = [NSIndexPath indexPathForRow:(LoopMaxCount / 2 *[_dataArrays GetCount]) inSection:0];
    [self change_index:[_model GetPropertyValue:@"index"]];
}
#pragma mark - 私有方法
- (UIView *)getInsertView:(int)index
{
    if ([_dataArrays GetCount]==0 || !_dataArrays) {
        return nil;
    }
    if (index<0) {
        index = 0;
    }else if(index>=[_dataArrays GetCount]) {
        index = [_dataArrays GetCount]-1;
    }
    if (_cellTemplatesArray.count==0 || !_cellTemplatesArray) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : @"模板为空或者下标越界"];
        return nil;
    }
    id jsonValue = [_dataArrays GetData:index];
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger:dataNode :@"template" :0];
    NSString *template;
    @try {
        if (_cellTemplatesArray.count <= 0) {
            [NSException raise:@"CoverFlow" format:@"模板不能为空"];
        }
        else if (cellIndex >= _cellTemplatesArray.count || cellIndex < 0)
        {
            [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"下标为%i的模板越界",cellIndex]];
            cellIndex = 0;
        }
        template = _cellTemplatesArray[cellIndex];
        NSString * imagePath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :template];
        if(![doIOHelper ExistFile:imagePath]){
            NSString *reason = [NSString stringWithFormat:@"模板%@不存在",template];
            NSException *ex = [[NSException alloc]initWithName:@"do_CoverFlowView" reason:reason userInfo:nil];
            [[doServiceContainer Instance].LogEngine WriteError:ex :@"模板错误"] ;
            return nil;
        }
        if (cellIndex >= _cellTemplatesArray.count) {
            cellIndex = 0;
        }
        doUIModule *cellMode;
        cellMode = [[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile:template :_model.CurrentPage :YES];

        [cellMode.CurrentUIModuleView OnRedraw];
        [cellMode SetModelData:jsonValue];
        UIView *insetView = (UIView *)cellMode.CurrentUIModuleView;
        return insetView;
    }
    @catch (NSException *exception)
    {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
        return nil;
    }
}
#pragma mark - UICollectionViewDataSource方法
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!_cellTemplatesArray || _cellTemplatesArray.count==0) {
        _isValidateTemplate = NO;
        NSString *reason = [NSString stringWithFormat:@"模板为空"];
        NSException *ex = [[NSException alloc]initWithName:@"do_CoverFlowView" reason:reason userInfo:nil];
        [[doServiceContainer Instance].LogEngine WriteError:ex :@"模板错误"] ;
        return 0;
    }
    if (isLoop) {
        
        return _indexCache.count;
    }
    return [_dataArrays GetCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CoverID forIndexPath:indexPath];
    NSInteger index = indexPath.row;
    if (isLoop) {
        index = [[_indexCache objectAtIndex:indexPath.row] integerValue];
    }
    UIView *contentView = [self getInsertView:(int)index];
    contentView.frame = CGRectMake(0, 0, contentView.frame.size.width, contentView.frame.size.height);
    if (cell.contentView.subviews.count >=1) {
        [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
    }
    [cell.contentView addSubview:contentView];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    int index = indexPath.row % [_dataArrays GetCount];
    [node setObject:@(index) forKey:@"index"];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"touch" :invokeResult];
    NSString *curIndex = [_model GetPropertyValue:@"index"];
    
    if (index != [curIndex integerValue]) {
        NSString *strIndex = [NSString stringWithFormat:@"%d",index];
        [_model SetPropertyValue:@"index" :strIndex];
        doInvokeResult *indexResult = [[doInvokeResult alloc]init];
        [indexResult SetResultText:strIndex];
        [_model.EventCenter FireEvent:@"indexChanged" :indexResult];
    }
    if (isLoop) {
        currentIndexPath = indexPath;
    }
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];

}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!cellView) {
        cellView = [self getInsertView:(int)indexPath.row];
    }
    return cellView.frame.size;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (!cellView) {
        cellView = [self getInsertView:(int)section];
    }
    return UIEdgeInsetsMake(0,(_model.RealWidth - cellView.frame.size.width) / 2, 0,(_model.RealWidth - cellView.frame.size.width) / 2);
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat width = (spcan) + cellView.frame.size.width;
    int index = roundf((scrollView.contentOffset.x  ) / width);
    if (isLoop) {
        index = index % ([_dataArrays GetCount]);
    }
    else
    {
        index = index % ([_dataArrays GetCount] +1);
    }
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultText:[NSString stringWithFormat:@"%ld",(long)index]];
    [_model.EventCenter FireEvent:@"indexChanged" :invokeResult];
    [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%d",index]];
    if (isLoop) {
        currentIndexPath = [NSIndexPath indexPathForRow:(LoopMaxCount/2 * [_dataArrays GetCount] + index) inSection:0];
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:(LoopMaxCount/2 * [_dataArrays GetCount] + index)inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    scrollView.decelerationRate = 0;
}
#pragma mark - UICollectionViewDelegate方法


#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
