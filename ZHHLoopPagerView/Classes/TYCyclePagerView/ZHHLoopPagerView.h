//
//  ZHHLoopPagerView.h
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>
#if __has_include(<ZHHLoopPagerView/ZHHLoopPagerView.h>)
#import <ZHHLoopPagerView/ZHHLoopPagerTransformLayout.h>
#else
#import "ZHHLoopPagerTransformLayout.h"
#endif
#if __has_include(<ZHHLoopPagerView/ZHHPageControl.h>)
#import <ZHHLoopPagerView/ZHHPageControl.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// 结构体：保存页面索引和对应的段落索引
typedef struct {
    // 当前页面的索引
    NSInteger index;
    // 当前页面所在的段落索引
    NSInteger section;
} ZHHIndexSection;

// 枚举：表示分页视图的滚动方向
typedef NS_ENUM(NSUInteger, ZHHPagerScrollDirection) {
    /// 向左滚动
    ZHHPagerScrollDirectionLeft,
    /// 向右滚动
    ZHHPagerScrollDirectionRight
};

@class ZHHLoopPagerView;

@protocol ZHHLoopPagerViewDataSource <NSObject>

/// 返回分页视图中的项目数量
- (NSInteger)numberOfItemsInPagerView:(ZHHLoopPagerView *)pageView;

/// 返回指定索引的单元格
- (__kindof UICollectionViewCell *)pagerView:(ZHHLoopPagerView *)pagerView cellForItemAtIndex:(NSInteger)index;

/// 返回分页视图的布局信息，并进行缓存
- (ZHHLoopPagerViewLayout *)layoutForPagerView:(ZHHLoopPagerView *)pageView;

@end

/// 分页视图的代理协议
@protocol ZHHLoopPagerViewDelegate <NSObject>

@optional

/// 当分页视图滚动到新页面时调用
/// @param fromIndex 滚动前的索引
/// @param toIndex 滚动后的目标索引
- (void)pagerView:(ZHHLoopPagerView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/// 当选择了分页视图中的单元格时调用
/// @param cell 被选中的单元格
/// @param index 被选中的单元格索引
- (void)pagerView:(ZHHLoopPagerView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndex:(NSInteger)index;

/// 当选择了分页视图中的单元格时调用（带有索引段信息）
/// @param cell 被选中的单元格
/// @param indexSection 被选中的单元格的索引段信息
- (void)pagerView:(ZHHLoopPagerView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndexSection:(ZHHIndexSection)indexSection;

// 自定义布局的代理方法

/// 用于初始化分页视图项的变换属性
/// @param attributes 项目的布局属性
- (void)pagerView:(ZHHLoopPagerView *)pageView initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

/// 用于应用分页视图项的变换属性
/// @param attributes 项目的布局属性
- (void)pagerView:(ZHHLoopPagerView *)pageView applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

// 滚动视图代理方法

/// 当分页视图滚动时调用
- (void)pagerViewDidScroll:(ZHHLoopPagerView *)pageView;

/// 当开始拖动分页视图时调用
- (void)pagerViewWillBeginDragging:(ZHHLoopPagerView *)pageView;

/// 当拖动结束时调用
/// @param decelerate 是否需要减速
- (void)pagerViewDidEndDragging:(ZHHLoopPagerView *)pageView willDecelerate:(BOOL)decelerate;

/// 当开始减速滚动时调用
- (void)pagerViewWillBeginDecelerating:(ZHHLoopPagerView *)pageView;

/// 当减速滚动结束时调用
- (void)pagerViewDidEndDecelerating:(ZHHLoopPagerView *)pageView;

/// 当开始滚动动画时调用
- (void)pagerViewWillBeginScrollingAnimation:(ZHHLoopPagerView *)pageView;

/// 当滚动动画结束时调用
- (void)pagerViewDidEndScrollingAnimation:(ZHHLoopPagerView *)pageView;

@end


@interface ZHHLoopPagerView : UIView

/// 将自动调整大小以适应分页视图
@property (nonatomic, strong, nullable) UIView *backgroundView;

/// 数据源代理
@property (nonatomic, weak, nullable) id<ZHHLoopPagerViewDataSource> dataSource;

/// 代理
@property (nonatomic, weak, nullable) id<ZHHLoopPagerViewDelegate> delegate;

/// 分页视图，不能设置数据源和代理
@property (nonatomic, weak, readonly) UICollectionView *collectionView;

/// 分页视图布局
@property (nonatomic, strong, readonly) ZHHLoopPagerViewLayout *layout;

/// 是否为无限循环的分页视图
@property (nonatomic, assign) BOOL isInfiniteLoop;

/// 分页视图自动滚动时间间隔，默认值为0，禁用自动滚动
@property (nonatomic, assign) CGFloat autoScrollInterval;

/// 是否需要在重新加载数据时重置索引
@property (nonatomic, assign) BOOL reloadDataNeedResetIndex;

/// 当前页索引
@property (nonatomic, assign, readonly) NSInteger curIndex;

/// 当前页索引段信息
@property (nonatomic, assign, readonly) ZHHIndexSection indexSection;

// 滚动视图相关属性

/// 当前分页视图的偏移量
@property (nonatomic, assign, readonly) CGPoint contentOffset;

/// 当前分页视图是否正在跟踪
@property (nonatomic, assign, readonly) BOOL tracking;

/// 当前分页视图是否正在拖拽
@property (nonatomic, assign, readonly) BOOL dragging;

/// 当前分页视图是否正在减速
@property (nonatomic, assign, readonly) BOOL decelerating;

/// 重新加载数据，重要：会清空布局并调用代理方法layoutForPagerView
- (void)reloadData;

/// 更新数据，和重新加载数据类似，但不清空布局
- (void)updateData;

/// 如果只需要更新布局
- (void)setNeedUpdateLayout;

/// 清空布局并调用代理的layoutForPagerView
- (void)setNeedClearLayout;

/// 获取当前页的单元格
- (__kindof UICollectionViewCell * _Nullable)curIndexCell;

/// 获取可见的单元格
- (NSArray<__kindof UICollectionViewCell *> *_Nullable)visibleCells;

/// 获取可见的分页视图索引，可能会重复
- (NSArray *)visibleIndexs;

/// 滚动到指定索引的项
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;

/// 滚动到指定的索引段项
- (void)scrollToItemAtIndexSection:(ZHHIndexSection)indexSection animate:(BOOL)animate;

/// 滚动到下一个或前一个项
- (void)scrollToNearlyIndexAtDirection:(ZHHPagerScrollDirection)direction animate:(BOOL)animate;

/// 注册分页视图单元格类
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;

/// 注册分页视图单元格NIB
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/// 从重用池中取出分页视图单元格
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
