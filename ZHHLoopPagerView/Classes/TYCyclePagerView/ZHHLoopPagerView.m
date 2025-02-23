//
//  ZHHLoopPagerView.m
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import "ZHHLoopPagerView.h"

/// 比较两个 `ZHHIndexSection` 是否相等
/// @param indexSection1 第一个 `ZHHIndexSection`
/// @param indexSection2 第二个 `ZHHIndexSection`
/// @return 如果两个 `ZHHIndexSection` 的 `index` 和 `section` 都相等，返回 `YES`，否则返回 `NO`
NS_INLINE BOOL ZHHEqualIndexSection(ZHHIndexSection indexSection1, ZHHIndexSection indexSection2) {
    return indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section;
}

/// 创建一个新的 `ZHHIndexSection`
/// @param index 索引
/// @param section 段信息
/// @return 创建的 `ZHHIndexSection`
NS_INLINE ZHHIndexSection ZHHMakeIndexSection(NSInteger index, NSInteger section) {
    ZHHIndexSection indexSection;
    indexSection.index = index;
    indexSection.section = section;
    return indexSection;
}

@interface ZHHLoopPagerView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ZHHLoopPagerTransformLayoutDelegate> {
    // 存储代理方法标志
    struct {
        unsigned int pagerViewDidScroll   :1; // 标志是否实现了 `pagerViewDidScroll` 方法
        unsigned int didScrollFromIndexToNewIndex   :1; // 标志是否实现了 `didScrollFromIndexToNewIndex` 方法
        unsigned int initializeTransformAttributes   :1; // 标志是否实现了 `initializeTransformAttributes` 方法
        unsigned int applyTransformToAttributes   :1; // 标志是否实现了 `applyTransformToAttributes` 方法
    } _delegateFlags;

    // 存储数据源方法标志
    struct {
        unsigned int cellForItemAtIndex   :1; // 标志是否实现了 `cellForItemAtIndex` 方法
        unsigned int layoutForPagerView   :1; // 标志是否实现了 `layoutForPagerView` 方法
    } _dataSourceFlags;
}

// UI
@property (nonatomic, weak) UICollectionView *collectionView; // 用于展示内容的 UICollectionView
@property (nonatomic, strong) ZHHLoopPagerViewLayout *layout; // 分页视图的布局对象
@property (nonatomic, strong) NSTimer *timer; // 定时器，用于自动滚动

// Data
@property (nonatomic, assign) NSInteger numberOfItems; // 页面上的项数，通常是数据源中的项数

@property (nonatomic, assign) NSInteger dequeueSection; // 用于跟踪已经出列的 section，通常与分页滚动有关
@property (nonatomic, assign) ZHHIndexSection beginDragIndexSection; // 拖动开始时的索引段信息
@property (nonatomic, assign) NSInteger firstScrollIndex; // 第一次滚动时的索引

@property (nonatomic, assign) BOOL needClearLayout; // 是否需要清除布局
@property (nonatomic, assign) BOOL didReloadData; // 是否已经重新加载数据
@property (nonatomic, assign) BOOL didLayout; // 是否已经布局过
@property (nonatomic, assign) BOOL needResetIndex; // 是否需要重置索引
@end

#define kPagerViewMaxSectionCount 200
#define kPagerViewMinSectionCount 18

@implementation ZHHLoopPagerView

// 初始化方法，指定frame
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureProperty]; // 配置属性的默认值
        [self addCollectionView]; // 添加分页视图的集合视图
    }
    return self;
}

// 从xib或storyboard加载时调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configureProperty]; // 配置属性的默认值
        [self addCollectionView]; // 添加分页视图的集合视图
    }
    return self;
}

// 配置属性的默认值
- (void)configureProperty {
    _needResetIndex = NO; // 不需要重置索引
    _didReloadData = NO; // 数据没有被重新加载
    _didLayout = NO; // 布局没有被完成
    _autoScrollInterval = 0; // 自动滚动间隔为0，禁用自动滚动
    _isInfiniteLoop = YES; // 默认开启无限循环
    _beginDragIndexSection.index = 0; // 拖动开始的索引为0
    _beginDragIndexSection.section = 0; // 拖动开始的section为0
    _indexSection.index = -1; // 当前索引设置为-1，表示未初始化
    _indexSection.section = -1; // 当前section设置为-1，表示未初始化
    _firstScrollIndex = -1; // 第一次滚动的索引设置为-1，表示未初始化
}

// 添加集合视图的方法
- (void)addCollectionView {
    // 创建自定义布局
    ZHHLoopPagerTransformLayout *layout = [[ZHHLoopPagerTransformLayout alloc] init];
    // 初始化集合视图，传入自定义布局
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    // 如果delegate支持 applyTransformToAttributes 方法，设置布局的代理
    layout.delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    // 设置背景色为透明
    collectionView.backgroundColor = [UIColor clearColor];
    // 设置数据源和代理
    collectionView.dataSource = self;
    collectionView.delegate = self;
    // 关闭分页效果
    collectionView.pagingEnabled = NO;
    // 设置减速速率
    collectionView.decelerationRate = 1-0.0076;
    // 如果设备支持预取功能，禁用预取
    if ([collectionView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
        collectionView.prefetchingEnabled = NO;
    }
    
    // 隐藏水平滚动条
    collectionView.showsHorizontalScrollIndicator = NO;
    // 隐藏垂直滚动条
    collectionView.showsVerticalScrollIndicator = NO;
    // 将集合视图添加到父视图
    [self addSubview:collectionView];
    // 保存对集合视图的引用
    _collectionView = collectionView;
}

// 父视图变化时的回调方法
- (void)willMoveToSuperview:(UIView *)newSuperview {
    // 如果父视图为空，移除定时器
    if (!newSuperview) {
        [self removeTimer];
    } else {
        // 如果父视图不为空，移除旧定时器
        [self removeTimer];
        
        // 如果设置了自动滚动间隔，添加新的定时器
        if (_autoScrollInterval > 0) {
            [self addTimer];
        }
    }
}

#pragma mark - timer

// 添加定时器方法
- (void)addTimer {
    // 如果定时器已经存在或自动滚动间隔小于等于0，则直接返回
    if (_timer || _autoScrollInterval <= 0) {
        return;
    }
    
    // 创建定时器，设置时间间隔、目标对象、回调方法等
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
    // 将定时器添加到主运行循环，确保在主线程执行
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

// 移除定时器方法
- (void)removeTimer {
    if (!_timer) {
        return;
    }
    
    [_timer invalidate];
    _timer = nil;
}

// 定时器触发时的回调方法
- (void)timerFired:(NSTimer *)timer {
    // 如果视图没有父视图、没有窗口，或者没有内容，或者正在拖动，则不执行滚动
    if (!self.superview || !self.window || _numberOfItems == 0 || self.tracking) {
        return;
    }
    
    // 自动滚动到下一个项目，方向是向右，且带动画效果
    [self scrollToNearlyIndexAtDirection:ZHHPagerScrollDirectionRight animate:YES];
}

#pragma mark - getter

// layout 属性懒加载
- (ZHHLoopPagerViewLayout *)layout {
    if (!_layout) {
        // 如果数据源实现了 layoutForPagerView 方法，调用它来获取布局对象
        if (_dataSourceFlags.layoutForPagerView) {
            _layout = [_dataSource layoutForPagerView:self];
            _layout.isInfiniteLoop = _isInfiniteLoop;
        }
        
        // 如果布局对象的尺寸无效，设置 _layout 为 nil
        if (_layout.itemSize.width <= 0 || _layout.itemSize.height <= 0) {
            _layout = nil;
        }
    }
    return _layout;
}

// 当前页面的索引
- (NSInteger)curIndex {
    return _indexSection.index;
}

// 获取当前内容偏移量
- (CGPoint)contentOffset {
    return _collectionView.contentOffset;
}

// 是否正在追踪手势
- (BOOL)tracking {
    return _collectionView.tracking;
}

// 是否正在拖动
- (BOOL)dragging {
    return _collectionView.dragging;
}

// 是否正在减速
- (BOOL)decelerating {
    return _collectionView.decelerating;
}

// 获取背景视图
- (UIView *)backgroundView {
    return _collectionView.backgroundView;
}

// 获取当前索引对应的单元格
- (__kindof UICollectionViewCell *)curIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

// 获取当前可见的单元格
- (NSArray<__kindof UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

// 获取当前可见的单元格的索引
- (NSArray *)visibleIndexs {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [indexs addObject:@(indexPath.item)];
    }
    return [indexs copy];
}

#pragma mark - setter

// 设置背景视图
- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

// 设置自动滚动时间间隔
- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    
    // 移除现有的定时器
    [self removeTimer];
    
    // 如果时间间隔大于0，并且当前视图已经添加到父视图中，则添加定时器
    if (autoScrollInterval > 0 && self.superview) {
        [self addTimer];
    }
}

// 设置代理
- (void)setDelegate:(id<ZHHLoopPagerViewDelegate>)delegate {
    _delegate = delegate;
    
    // 检查代理是否实现了特定的方法，并记录相应的标志
    _delegateFlags.pagerViewDidScroll = [delegate respondsToSelector:@selector(pagerViewDidScroll:)];
    _delegateFlags.didScrollFromIndexToNewIndex = [delegate respondsToSelector:@selector(pagerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)];
    
    // 如果 collectionView 和布局已初始化，设置自定义布局的委托
    if (self.collectionView && self.collectionView.collectionViewLayout) {
        ((ZHHLoopPagerTransformLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    }
}

// 设置数据源
- (void)setDataSource:(id<ZHHLoopPagerViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    // 检查数据源是否实现了特定的方法，并记录相应的标志
    _dataSourceFlags.cellForItemAtIndex = [dataSource respondsToSelector:@selector(pagerView:cellForItemAtIndex:)];
    _dataSourceFlags.layoutForPagerView = [dataSource respondsToSelector:@selector(layoutForPagerView:)];
}

#pragma mark - public

// 重新加载数据
- (void)reloadData {
    _didReloadData = YES;
    _needResetIndex = YES;
    [self setNeedClearLayout];  // 设置需要清除布局
    [self clearLayout];  // 清除布局
    [self updateData];  // 更新数据
}

// 更新数据（不清除布局）
- (void)updateData {
    [self updateLayout];  // 更新布局
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];  // 获取数据源中项目的数量
    [_collectionView reloadData];  // 刷新 collectionView 的数据
    if (!_didLayout && !CGRectIsEmpty(self.collectionView.frame) && _indexSection.index < 0) {
        _didLayout = YES;  // 如果布局尚未完成且 collectionView 的框架有效，更新布局标志
    }
    
    BOOL needResetIndex = _needResetIndex && _reloadDataNeedResetIndex;
    _needResetIndex = NO;
    
    // 如果需要重置索引，则移除定时器
    if (needResetIndex) {
        [self removeTimer];
    }
    
    // 重置分页视图的索引
    [self resetPagerViewAtIndex:( (_indexSection.index < 0 && !CGRectIsEmpty(self.collectionView.frame)) || needResetIndex ) ? 0 : _indexSection.index];
    
    // 如果需要重置索引，则重新添加定时器
    if (needResetIndex) {
        [self addTimer];
    }
}

// 根据滚动方向滚动到下一个或上一个索引
- (void)scrollToNearlyIndexAtDirection:(ZHHPagerScrollDirection)direction animate:(BOOL)animate {
    ZHHIndexSection indexSection = [self nearlyIndexPathAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

// 滚动到指定的项索引
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (!_didLayout && _didReloadData) {
        _firstScrollIndex = index;  // 如果布局尚未完成并且数据已重新加载，记录第一次滚动的索引
    } else {
        _firstScrollIndex = -1;
    }
    
    // 如果不是无限循环滚动，直接滚动到指定索引
    if (!_isInfiniteLoop) {
        [self scrollToItemAtIndexSection:ZHHMakeIndexSection(index, 0) animate:animate];
        return;
    }
    
    // 如果是无限循环滚动，滚动到指定索引，且考虑当前索引的段
    [self scrollToItemAtIndexSection:ZHHMakeIndexSection(index, index >= self.curIndex ? _indexSection.section : _indexSection.section + 1) animate:animate];
}

// 滚动到指定的索引段
- (void)scrollToItemAtIndexSection:(ZHHIndexSection)indexSection animate:(BOOL)animate {
    if (_numberOfItems <= 0 || ![self isValidIndexSection:indexSection]) {
        return;  // 如果项数小于等于0或索引段无效，则不执行滚动
    }
    
    // 在动画开始前调用代理方法
    if (animate && [_delegate respondsToSelector:@selector(pagerViewWillBeginScrollingAnimation:)]) {
        [_delegate pagerViewWillBeginScrollingAnimation:self];
    }
    
    // 计算目标偏移量并滚动
    CGFloat offset = [self caculateOffsetXAtIndexSection:indexSection];
    [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
}

// 注册类视图单元格
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

// 注册Nib视图单元格
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

// 从重用队列中获取单元格
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_dequeueSection]];
    return cell;
}

#pragma mark - configure layout

// 更新布局
- (void)updateLayout {
    // 如果布局不存在，则不做任何操作
    if (!self.layout) {
        return;
    }
    // 设置布局的无限循环属性
    self.layout.isInfiniteLoop = _isInfiniteLoop;
    
    // 设置 collectionView 的布局，更新为当前的 layout
    ((ZHHLoopPagerTransformLayout *)_collectionView.collectionViewLayout).layout = self.layout;
}

// 清除布局
- (void)clearLayout {
    // 如果需要清除布局，设置布局为空，并重置标志
    if (_needClearLayout) {
        _layout = nil;
        _needClearLayout = NO;
    }
}

// 设置需要清除布局标志
- (void)setNeedClearLayout {
    _needClearLayout = YES;
}

// 请求更新布局
- (void)setNeedUpdateLayout {
    // 如果布局不存在，则不做任何操作
    if (!self.layout) {
        return;
    }
    
    // 清除当前布局
    [self clearLayout];
    // 更新布局
    [self updateLayout];
    // 刷新 collectionView 的布局
    [_collectionView.collectionViewLayout invalidateLayout];
    
    // 重置分页视图的索引
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 :_indexSection.index];
}

#pragma mark - pager index

// 判断一个 ZHHIndexSection 是否有效
- (BOOL)isValidIndexSection:(ZHHIndexSection)indexSection {
    // 确保 index 在有效范围内，section 也在有效范围内
    return indexSection.index >= 0 && indexSection.index < _numberOfItems
        && indexSection.section >= 0 && indexSection.section < kPagerViewMaxSectionCount;
}

// 获取下一个要显示的页面索引，根据滚动方向来决定
- (ZHHIndexSection)nearlyIndexPathAtDirection:(ZHHPagerScrollDirection)direction {
    // 根据当前索引和方向，返回下一个索引
    return [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
}

// 根据当前的 indexSection 和滚动方向计算下一个即将显示的页面索引
- (ZHHIndexSection)nearlyIndexPathForIndexSection:(ZHHIndexSection)indexSection direction:(ZHHPagerScrollDirection)direction {
    // 如果 indexSection 无效（index 越界），直接返回原来的 indexSection
    if (indexSection.index < 0 || indexSection.index >= _numberOfItems) {
        return indexSection;
    }
    
    // 如果没有开启无限循环
    if (!_isInfiniteLoop) {
        // 向右滚动且已经是最后一项，返回第一项（如果有自动滚动则滚动到第一个，否则保持在当前项）
        if (direction == ZHHPagerScrollDirectionRight && indexSection.index == _numberOfItems - 1) {
            return _autoScrollInterval > 0 ? ZHHMakeIndexSection(0, 0) : indexSection;
        }
        // 向右滚动，返回当前项的下一个项
        else if (direction == ZHHPagerScrollDirectionRight) {
            return ZHHMakeIndexSection(indexSection.index+1, 0);
        }
        
        // 向左滚动且已经是第一项，返回最后一项（如果有自动滚动则滚动到最后一项，否则保持在当前项）
        if (indexSection.index == 0) {
            return _autoScrollInterval > 0 ? ZHHMakeIndexSection(_numberOfItems - 1, 0) : indexSection;
        }
        // 向左滚动，返回当前项的上一个项
        return ZHHMakeIndexSection(indexSection.index-1, 0);
    }
    
    // 如果开启了无限循环
    if (direction == ZHHPagerScrollDirectionRight) {
        // 向右滚动，返回当前项的下一个项
        if (indexSection.index < _numberOfItems-1) {
            return ZHHMakeIndexSection(indexSection.index+1, indexSection.section);
        }
        // 如果已经是最大的 section，保持 section 不变
        if (indexSection.section >= kPagerViewMaxSectionCount-1) {
            return ZHHMakeIndexSection(indexSection.index, kPagerViewMaxSectionCount-1);
        }
        // 否则，滚动到下一个 section 的第一项
        return ZHHMakeIndexSection(0, indexSection.section+1);
    }
    
    // 向左滚动，返回当前项的上一个项
    if (indexSection.index > 0) {
        return ZHHMakeIndexSection(indexSection.index-1, indexSection.section);
    }
    
    // 如果已经是第一项，且 section 也为 0，则保持不变
    if (indexSection.section <= 0) {
        return ZHHMakeIndexSection(indexSection.index, 0);
    }
    
    // 否则，返回前一个 section 的最后一项
    return ZHHMakeIndexSection(_numberOfItems-1, indexSection.section-1);
}

// 根据偏移量计算当前显示的页面索引
- (ZHHIndexSection)caculateIndexSectionWithOffsetX:(CGFloat)offsetX {
    // 如果没有项目，直接返回 (0, 0)
    if (_numberOfItems <= 0) {
        return ZHHMakeIndexSection(0, 0);
    }
    
    // 获取布局对象
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    
    // 计算左边距，区分是否开启无限循环
    CGFloat leftEdge = _isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
    
    // 获取 UICollectionView 的宽度
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    
    // 计算中间偏移量
    CGFloat middleOffset = offsetX + width / 2;
    
    // 计算每个 item 的宽度（包括 item 之间的间隔）
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    
    // 当前的 index 和 section 初始化为 0
    NSInteger curIndex = 0;
    NSInteger curSection = 0;
    
    // 确保中间偏移量有效
    if (middleOffset - leftEdge >= 0) {
        // 根据偏移量计算当前 item 的索引
        NSInteger itemIndex = (middleOffset - leftEdge + layout.minimumInteritemSpacing / 2) / itemWidth;
        
        // 防止 itemIndex 越界
        if (itemIndex < 0) {
            itemIndex = 0;
        } else if (itemIndex >= _numberOfItems * kPagerViewMaxSectionCount) {
            itemIndex = _numberOfItems * kPagerViewMaxSectionCount - 1;
        }
        
        // 通过 itemIndex 计算当前的 item 和 section
        curIndex = itemIndex % _numberOfItems;
        curSection = itemIndex / _numberOfItems;
    }
    
    // 返回计算得到的 IndexSection
    return ZHHMakeIndexSection(curIndex, curSection);
}

// 计算根据当前的 indexSection 获取的 offsetX 偏移量
- (CGFloat)caculateOffsetXAtIndexSection:(ZHHIndexSection)indexSection{
    // 如果没有项目，返回偏移量 0
    if (_numberOfItems == 0) {
        return 0;
    }
    
    // 获取布局对象
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    // 获取边距，区分是否开启无限循环
    UIEdgeInsets edge = _isInfiniteLoop ? _layout.sectionInset : _layout.onlyOneSectionInset;
    // 左边距和右边距
    CGFloat leftEdge = edge.left;
    CGFloat rightEdge = edge.right;
    
    // 获取 UICollectionView 的宽度
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    
    // 计算每个 item 的宽度（包括 item 之间的间隔）
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    
    // 偏移量初始化为 0
    CGFloat offsetX = 0;
    
    // 如果不是无限循环且 item 没有居中，且当前索引是最后一个 item
    if (!_isInfiniteLoop && !_layout.itemHorizontalCenter && indexSection.index == _numberOfItems - 1) {
        // 计算当前 item 的偏移量
        offsetX = leftEdge + itemWidth * (indexSection.index + indexSection.section * _numberOfItems) - (width - itemWidth) - layout.minimumInteritemSpacing + rightEdge;
    } else {
        // 否则，计算常规偏移量，确保 item 居中
        offsetX = leftEdge + itemWidth * (indexSection.index + indexSection.section * _numberOfItems) - layout.minimumInteritemSpacing / 2 - (width - itemWidth) / 2;
    }
    
    // 返回偏移量，确保不会小于 0
    return MAX(offsetX, 0);
}

// 重置分页视图到指定的索引位置
- (void)resetPagerViewAtIndex:(NSInteger)index {
    // 如果布局已经完成并且首次滚动的索引大于等于 0，使用首次滚动的索引
    if (_didLayout && _firstScrollIndex >= 0) {
        index = _firstScrollIndex;  // 将索引设置为首次滚动的索引
        _firstScrollIndex = -1;  // 重置首次滚动索引
    }

    // 如果索引小于 0，直接返回
    if (index < 0) {
        return;
    }
    
    // 如果索引大于等于项目数，将索引重置为 0
    if (index >= _numberOfItems) {
        index = 0;
    }

    // 根据计算出的索引，滚动到指定的位置，不带动画
    [self scrollToItemAtIndexSection:ZHHMakeIndexSection(index, _isInfiniteLoop ? kPagerViewMaxSectionCount / 3 : 0) animate:NO];
    
    // 如果不是无限循环且当前索引小于 0，手动触发 scrollViewDidScroll 方法
    if (!_isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

// 根据需要回收分页视图
- (void)recyclePagerViewIfNeed {
    // 如果不是无限循环，直接返回，不进行回收
    if (!_isInfiniteLoop) {
        return;
    }
    
    // 如果当前分页视图的 section 超过了最大范围或者小于最小范围，则执行回收操作
    if (_indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount || _indexSection.section < kPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];  // 重置分页视图到当前索引
    }
}

#pragma mark - UICollectionViewDataSource

// 返回 UICollectionView 的 section 数量。如果启用了无限循环，则返回最大 section 数量，否则返回 1
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _isInfiniteLoop ? kPagerViewMaxSectionCount : 1;
}

// 返回指定 section 中的 item 数量。通过数据源获取分页视图中的 item 数量，并赋值给 _numberOfItems
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];  // 从数据源获取 item 数量
    return _numberOfItems;
}

// 返回每个 item 对应的 cell。通过数据源提供的 cellForItemAtIndex 方法获取 cell，如果数据源没有提供，则触发断言
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _dequeueSection = indexPath.section;  // 设置当前 dequeue 的 section
    
    // 如果数据源实现了 cellForItemAtIndex 方法，则返回对应的 cell
    if (_dataSourceFlags.cellForItemAtIndex) {
       return [_dataSource pagerView:self cellForItemAtIndex:indexPath.row];
    }
    
    // 如果数据源没有实现该方法，触发断言
    NSAssert(NO, @"pagerView cellForItemAtIndex: is nil!");
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

// 返回每个 section 的边距（inset），根据是否启用了无限循环和 section 的不同，设置不同的边距
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!_isInfiniteLoop) {
        return _layout.onlyOneSectionInset;  // 如果没有启用无限循环，返回普通的单一 section 边距
    }
    
    // 如果启用了无限循环，根据 section 的位置返回不同的边距
    if (section == 0) {
        return _layout.firstSectionInset;  // 第一个 section 使用不同的边距
    } else if (section == kPagerViewMaxSectionCount - 1) {
        return _layout.lastSectionInset;  // 最后一个 section 使用不同的边距
    }
    
    // 其他中间的 section 使用不同的边距
    return _layout.middleSectionInset;
}

// 当用户点击了某个 item 时，通知代理，调用代理的方法进行处理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];  // 获取被点击的 cell
    
    // 如果代理实现了 didSelectedItemCell:atIndex: 方法，调用该方法
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndex:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndex:indexPath.item];
    }
    
    // 如果代理实现了 didSelectedItemCell:atIndexSection: 方法，调用该方法，传递 item 和 section 信息
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndexSection:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndexSection:ZHHMakeIndexSection(indexPath.item, indexPath.section)];
    }
}

#pragma mark - UIScrollViewDelegate

// 监听 UIScrollView 的滚动事件
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 如果视图尚未布局完成，直接返回
    if (!_didLayout) {
        return;
    }
    
    // 根据当前的滚动偏移量计算当前的 indexSection
    ZHHIndexSection newIndexSection = [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    
    // 如果没有有效的 items，或者新的 indexSection 不合法，输出日志并返回
    if (_numberOfItems <= 0 || ![self isValidIndexSection:newIndexSection]) {
        NSLog(@"inVlaidIndexSection:(%ld,%ld)!", (long)newIndexSection.index, (long)newIndexSection.section);
        return;
    }
    
    // 保存当前的 indexSection
    ZHHIndexSection indexSection = _indexSection;
    
    // 更新当前的 indexSection
    _indexSection = newIndexSection;
    
    // 如果代理实现了 pagerViewDidScroll: 方法，则调用代理方法
    if (_delegateFlags.pagerViewDidScroll) {
        [_delegate pagerViewDidScroll:self];
    }
    
    // 如果代理实现了 didScrollFromIndexToNewIndex 方法，且新的 indexSection 与当前的 indexSection 不相同，则通知代理滚动发生了变化
    if (_delegateFlags.didScrollFromIndexToNewIndex && !ZHHEqualIndexSection(_indexSection, indexSection)) {
        //NSLog(@"curIndex %ld", (long)_indexSection.index); // 可选的调试日志
        [_delegate pagerView:self didScrollFromIndex:MAX(indexSection.index, 0) toIndex:_indexSection.index];
    }
}

#pragma mark - UIScrollViewDelegate

// 触发滚动视图开始拖动时调用
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 如果开启了自动滚动定时器，停止定时器
    if (_autoScrollInterval > 0) {
        [self removeTimer];
    }
    
    // 记录当前拖动时的索引位置（根据偏移量计算）
    _beginDragIndexSection = [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    
    // 如果代理实现了 pagerViewWillBeginDragging: 方法，通知代理
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDragging:)]) {
        [_delegate pagerViewWillBeginDragging:self];
    }
}

// 触发滚动视图停止拖动时调用
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    // 如果滑动速度小于阈值，或拖动前后的索引不同，则返回当前索引的偏移量
    if (fabs(velocity.x) < 0.35 || !ZHHEqualIndexSection(_beginDragIndexSection, _indexSection)) {
        // 设置目标偏移量为当前索引的位置
        targetContentOffset->x = [self caculateOffsetXAtIndexSection:_indexSection];
        return;
    }
    
    // 根据滑动方向来判断滚动方向，默认为向右滚动
    ZHHPagerScrollDirection direction = ZHHPagerScrollDirectionRight;
    if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
        direction = ZHHPagerScrollDirectionLeft; // 如果当前偏移量小于目标偏移量，说明是向左滚动
    }
    
    // 根据计算的滚动方向，获取目标索引路径
    ZHHIndexSection indexSection = [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    
    // 设置目标偏移量为目标索引位置的偏移量
    targetContentOffset->x = [self caculateOffsetXAtIndexSection:indexSection];
}

#pragma mark - UIScrollViewDelegate

// 滚动视图结束拖动时调用
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 如果开启了自动滚动定时器，重新开始定时器
    if (_autoScrollInterval > 0) {
        [self addTimer];
    }
    
    // 如果代理实现了 pagerViewDidEndDragging:willDecelerate: 方法，通知代理
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDragging:willDecelerate:)]) {
        [_delegate pagerViewDidEndDragging:self willDecelerate:decelerate];
    }
}

// 滚动视图将要开始减速时调用
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    // 如果代理实现了 pagerViewWillBeginDecelerating: 方法，通知代理
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDecelerating:)]) {
        [_delegate pagerViewWillBeginDecelerating:self];
    }
}

// 滚动视图结束减速时调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 如果需要回收页面视图，执行回收操作
    [self recyclePagerViewIfNeed];
    
    // 如果代理实现了 pagerViewDidEndDecelerating: 方法，通知代理
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDecelerating:)]) {
        [_delegate pagerViewDidEndDecelerating:self];
    }
}

// 滚动视图结束滚动动画时调用
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // 如果需要回收页面视图，执行回收操作
    [self recyclePagerViewIfNeed];
    
    // 如果代理实现了 pagerViewDidEndScrollingAnimation: 方法，通知代理
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndScrollingAnimation:)]) {
        [_delegate pagerViewDidEndScrollingAnimation:self];
    }
}

#pragma mark - ZHHCyclePagerTransformLayoutDelegate

// 初始化布局属性时调用
- (void)pagerViewTransformLayout:(ZHHLoopPagerTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    // 如果代理实现了 initializeTransformAttributes 方法，通知代理初始化布局属性
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate pagerView:self initializeTransformAttributes:attributes];
    }
}

// 应用布局变换时调用
- (void)pagerViewTransformLayout:(ZHHLoopPagerTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    // 如果代理实现了 applyTransformToAttributes 方法，通知代理应用布局变换
    if (_delegateFlags.applyTransformToAttributes) {
        [_delegate pagerView:self applyTransformToAttributes:attributes];
    }
}

// 子视图布局更新时调用
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 检查是否需要更新布局，判断条件是：视图的 frame 是否与 _collectionView 的 frame 相同
    BOOL needUpdateLayout = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds; // 更新 collectionView 的 frame 与当前视图相同
    
    // 如果索引小于 0 或者需要更新布局，且数据数量大于 0 或者数据已经重新加载
    if ((_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData)) {
        _didLayout = YES;  // 标记布局已经完成
        [self setNeedUpdateLayout];  // 需要更新布局
    }
}

// 视图销毁时调用
- (void)dealloc {
    // 在销毁时，清除 delegate 和数据源引用，避免循环引用
    ((ZHHLoopPagerTransformLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

@end


