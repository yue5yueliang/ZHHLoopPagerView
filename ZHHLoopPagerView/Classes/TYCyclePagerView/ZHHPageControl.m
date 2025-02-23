//
//  ZHHPageControl.m
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import "ZHHPageControl.h"

@interface ZHHPageControl ()

// MARK: - UI 相关属性
/// 存储指示器视图的数组，用于显示当前页和其他页的指示器
@property (nonatomic, strong) NSArray<UIImageView *> *indicatorViews;

// MARK: - 数据相关属性
/// 强制更新标志位，用于控制是否强制刷新指示器
@property (nonatomic, assign) BOOL forceUpdate;

@end

@implementation ZHHPageControl

#pragma mark - 生命周期

// 初始化方法 - 使用 frame 初始化
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureProperties];  // 配置默认属性
    }
    return self;
}

// 初始化方法 - 使用编码器初始化
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configureProperties];  // 配置默认属性
    }
    return self;
}

// 配置默认属性
- (void)configureProperties {
    self.userInteractionEnabled = NO;  // 禁用用户交互
    _forceUpdate = NO;                 // 不强制更新
    _animateDuration = 0.3;              // 默认动画持续时间
    _pageIndicatorSpacing = 10;         // 默认指示器间距
    _indicatorImageContentMode = UIViewContentModeCenter; // 默认图片内容模式为居中
    _pageIndicatorSize = CGSizeMake(6, 6);  // 默认指示器大小
    _currentPageIndicatorSize = _pageIndicatorSize;  // 当前页指示器大小
    _pageIndicatorTintColor = [UIColor colorWithRed:128/255. green:128/255. blue:128/255. alpha:1]; // 默认页面指示器颜色
    _currentPageIndicatorTintColor = [UIColor whiteColor]; // 默认当前页面指示器颜色
}

// 当视图将要添加到父视图时调用
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        _forceUpdate = YES;  // 强制更新标志设置为YES
        [self updateIndicatorViews];  // 更新指示器视图
        _forceUpdate = NO;  // 更新完毕后重置强制更新标志
    }
}

#pragma mark - Getter & Setter

// 获取内容尺寸（contentSize）
- (CGSize)contentSize {
    // 计算总宽度 = (指示器数量 - 1) * (指示器宽度 + 间距) + 第一个指示器宽度 + 左右内边距
    CGFloat width = (_indicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpacing) + _pageIndicatorSize.width + _contentInset.left + _contentInset.right;
    // 高度为当前页面指示器的高度 + 上下内边距
    CGFloat height = _currentPageIndicatorSize.height + _contentInset.top + _contentInset.bottom;
    return CGSizeMake(width, height);  // 返回计算后的内容尺寸
}

// 设置页数（numberOfPages）
- (void)setNumberOfPages:(NSInteger)numberOfPages {
    // 如果页数没有变化，直接返回
    if (numberOfPages == _numberOfPages) {
        return;
    }
    _numberOfPages = numberOfPages;  // 更新页数
    
    // 如果当前页数大于总页数，重置当前页为0
    if (_currentPage >= numberOfPages) {
        _currentPage = 0;
    }
    
    // 更新指示器视图
    [self updateIndicatorViews];
    
    // 如果有指示器视图，标记需要重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

#pragma mark - 设置当前页

// 设置当前页（没有动画）
- (void)setCurrentPage:(NSInteger)currentPage {
    // 如果当前页和设置的页相同，或者设置的页数大于指示器视图数量，直接返回
    if (_currentPage == currentPage || _indicatorViews.count <= currentPage) {
        return;
    }
    
    _currentPage = currentPage;  // 更新当前页
    
    // 如果当前页指示器大小与默认大小不一致，则需要重新布局
    if (!CGSizeEqualToSize(_currentPageIndicatorSize, _pageIndicatorSize)) {
        [self setNeedsLayout];
    }
    
    // 更新指示器行为
    [self updateIndicatorViewsBehavior];
    
    // 如果控件可交互，发送值改变事件
    if (self.userInteractionEnabled) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

// 设置当前页（带动画）
- (void)setCurrentPage:(NSInteger)currentPage animate:(BOOL)animate {
    // 如果需要动画，使用动画设置当前页
    if (animate) {
        [UIView animateWithDuration:_animateDuration animations:^{
            [self setCurrentPage:currentPage];
        }];
    } else {
        // 如果不需要动画，直接设置当前页
        [self setCurrentPage:currentPage];
    }
}

#pragma mark - 设置指示器样式

// 设置页面指示器的图片
- (void)setPageIndicatorImage:(UIImage *)pageIndicatorImage {
    _pageIndicatorImage = pageIndicatorImage;  // 更新页面指示器图片
    [self updateIndicatorViewsBehavior];  // 更新指示器的行为（刷新视图）
}

// 设置当前页指示器的图片
- (void)setCurrentPageIndicatorImage:(UIImage *)currentPageIndicatorImage {
    _currentPageIndicatorImage = currentPageIndicatorImage;  // 更新当前页指示器图片
    [self updateIndicatorViewsBehavior];  // 更新指示器的行为（刷新视图）
}

// 设置页面指示器的颜色
- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
    _pageIndicatorTintColor = pageIndicatorTintColor;  // 更新页面指示器颜色
    [self updateIndicatorViewsBehavior];  // 更新指示器的行为（刷新视图）
}

// 设置当前页指示器的颜色
- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
    _currentPageIndicatorTintColor = currentPageIndicatorTintColor;  // 更新当前页指示器颜色
    [self updateIndicatorViewsBehavior];  // 更新指示器的行为（刷新视图）
}

// 设置页面指示器的尺寸
- (void)setPageIndicatorSize:(CGSize)pageIndicatorSize {
    // 如果新尺寸与旧尺寸相同，则不做任何处理
    if (CGSizeEqualToSize(_pageIndicatorSize, pageIndicatorSize)) {
        return;
    }
    
    _pageIndicatorSize = pageIndicatorSize;  // 更新页面指示器尺寸
    
    // 如果当前页指示器的尺寸为空或较小，则设置为与页面指示器相同的尺寸
    if (CGSizeEqualToSize(_currentPageIndicatorSize, CGSizeZero) || (_currentPageIndicatorSize.width < pageIndicatorSize.width && _currentPageIndicatorSize.height < pageIndicatorSize.height)) {
        _currentPageIndicatorSize = pageIndicatorSize;
    }
    
    // 如果指示器视图存在，重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

#pragma mark - 设置指示器的间距和对齐方式

// 设置页面指示器之间的间距
- (void)setPageIndicatorSpacing:(CGFloat)pageIndicatorSpacing {
    _pageIndicatorSpacing = pageIndicatorSpacing;  // 更新页面指示器间距
    // 如果指示器视图存在，重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

// 设置当前页指示器的尺寸
- (void)setCurrentPageIndicatorSize:(CGSize)currentPageIndicatorSize {
    // 如果新尺寸与旧尺寸相同，则不做任何处理
    if (CGSizeEqualToSize(_currentPageIndicatorSize, currentPageIndicatorSize)) {
        return;
    }
    
    _currentPageIndicatorSize = currentPageIndicatorSize;  // 更新当前页指示器尺寸
    
    // 如果指示器视图存在，重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

// 设置内容的水平对齐方式
- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    [super setContentHorizontalAlignment:contentHorizontalAlignment];  // 调用父类设置对齐方式
    // 如果指示器视图存在，重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

// 设置内容的垂直对齐方式
- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];  // 调用父类设置对齐方式
    // 如果指示器视图存在，重新布局
    if (_indicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}
#pragma mark - 更新指示器视图

// 更新指示器视图
- (void)updateIndicatorViews {
    // 如果没有父视图且没有强制更新标志，则直接返回
    if (!self.superview && !_forceUpdate) {
        return;
    }
    
    // 如果指示器数量与页数相等，直接更新指示器的行为
    if (_indicatorViews.count == _numberOfPages) {
        [self updateIndicatorViewsBehavior];
        return;
    }
    
    // 创建一个可变数组用于存放指示器视图
    NSMutableArray *indicatorViews = _indicatorViews ? [_indicatorViews mutableCopy] : [NSMutableArray array];
    
    // 如果指示器视图的数量小于页数，新增指示器视图
    if (indicatorViews.count < _numberOfPages) {
        for (NSInteger idx = indicatorViews.count; idx < _numberOfPages; ++idx) {
            UIImageView *indicatorView = [[UIImageView alloc] init];
            indicatorView.contentMode = _indicatorImageContentMode;  // 设置指示器的图片内容模式
            [self addSubview:indicatorView];  // 将指示器视图添加到当前视图
            [indicatorViews addObject:indicatorView];  // 将新创建的指示器视图加入数组
        }
    }
    // 如果指示器视图的数量大于页数，移除多余的指示器视图
    else if (indicatorViews.count > _numberOfPages) {
        for (NSInteger idx = indicatorViews.count - 1; idx >= _numberOfPages; --idx) {
            UIImageView *indicatorView = indicatorViews[idx];
            [indicatorView removeFromSuperview];  // 从父视图移除多余的指示器视图
            [indicatorViews removeObjectAtIndex:idx];  // 从数组中删除多余的指示器视图
        }
    }
    
    // 更新指示器视图数组
    _indicatorViews = [indicatorViews copy];
    
    // 更新指示器的行为（例如选中状态、颜色等）
    [self updateIndicatorViewsBehavior];
}

#pragma mark - 更新指示器行为

// 更新指示器的状态和行为（例如颜色、图片等）
- (void)updateIndicatorViewsBehavior {
    // 如果没有指示器视图，或者没有父视图且没有强制更新标志，直接返回
    if (_indicatorViews.count == 0 || (!self.superview && !_forceUpdate)) {
        return;
    }
    
    // 如果需要隐藏单页指示器，并且当前页只有一个指示器，则隐藏该指示器
    if (_hidesForSinglePage && _indicatorViews.count == 1) {
        UIImageView *indicatorView = _indicatorViews.lastObject;
        indicatorView.hidden = YES;
        return;
    }
    
    // 遍历所有指示器视图，更新它们的状态
    NSInteger index = 0;
    for (UIImageView *indicatorView in _indicatorViews) {
        if (_pageIndicatorImage) {
            // 如果有自定义的指示器图片，设置图片并根据当前页选择图片
            indicatorView.contentMode = _indicatorImageContentMode;
            indicatorView.image = _currentPage == index ? _currentPageIndicatorImage : _pageIndicatorImage;
        } else {
            // 如果没有自定义的指示器图片，使用背景颜色来表示当前页
            indicatorView.image = nil;
            indicatorView.backgroundColor = _currentPage == index ? _currentPageIndicatorTintColor : _pageIndicatorTintColor;
        }
        
        // 显示指示器
        indicatorView.hidden = NO;
        ++index;
    }
}

#pragma mark - 布局

// 布局指示器视图的位置和大小
- (void)layoutIndicatorViews {
    // 如果没有指示器视图，直接返回
    if (_indicatorViews.count == 0) {
        return;
    }
    
    // 初始化 X 轴坐标、Y 轴中心点坐标和间距
    CGFloat orignX = 0;
    CGFloat centerY = 0;
    CGFloat pageIndicatorSpacing = _pageIndicatorSpacing; // 页面指示器的间距
    
    // 根据水平方向的对齐方式计算 originX
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter:
            // 如果是居中对齐，忽略 contentInset
            orignX = (CGRectGetWidth(self.frame) - (_indicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpacing) - _currentPageIndicatorSize.width) / 2;
            break;
        case UIControlContentHorizontalAlignmentLeft:
            orignX = _contentInset.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
            orignX = CGRectGetWidth(self.frame) - ((_indicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpacing) + _currentPageIndicatorSize.width) - _contentInset.right;
            break;
        case UIControlContentHorizontalAlignmentFill:
            // 填充模式，计算每个指示器之间的间隔
            orignX = _contentInset.left;
            if (_indicatorViews.count > 1) {
                pageIndicatorSpacing = (CGRectGetWidth(self.frame) - _contentInset.left - _contentInset.right - _pageIndicatorSize.width - (_indicatorViews.count - 1) * _pageIndicatorSize.width) / (_indicatorViews.count - 1);
            }
            break;
        default:
            break;
    }
    
    // 根据垂直方向的对齐方式计算 centerY
    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            centerY = CGRectGetHeight(self.frame) / 2;
            break;
        case UIControlContentVerticalAlignmentTop:
            centerY = _contentInset.top + _currentPageIndicatorSize.height / 2;
            break;
        case UIControlContentVerticalAlignmentBottom:
            centerY = CGRectGetHeight(self.frame) - _currentPageIndicatorSize.height / 2 - _contentInset.bottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            centerY = (CGRectGetHeight(self.frame) - _contentInset.top - _contentInset.bottom) / 2 + _contentInset.top;
            break;
        default:
            break;
    }
    
    // 布局每个指示器视图
    NSInteger index = 0;
    for (UIImageView *indicatorView in _indicatorViews) {
        // 如果使用图片作为指示器，设置圆角为 0，否则根据当前页调整圆角
        if (_pageIndicatorImage) {
            indicatorView.layer.cornerRadius = 0;
        } else {
            indicatorView.layer.cornerRadius = _currentPage == index ? _currentPageIndicatorSize.height / 2 : _pageIndicatorSize.height / 2;
        }
        
        // 计算当前指示器的尺寸
        CGSize size = index == _currentPage ? _currentPageIndicatorSize : _pageIndicatorSize;
        
        // 设置指示器的位置和大小
        indicatorView.frame = CGRectMake(orignX, centerY - size.height / 2, size.width, size.height);
        
        // 更新下一个指示器的 X 轴坐标
        orignX += size.width + pageIndicatorSpacing;
        
        ++index;
    }
}

// 布局更新时调用
- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutIndicatorViews];
}

@end
