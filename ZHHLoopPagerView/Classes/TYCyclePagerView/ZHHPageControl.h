//
//  ZHHPageControl.h
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHHPageControl : UIControl

/// 页数，默认值为 0
@property (nonatomic, assign) NSInteger numberOfPages;

/// 当前页数，默认值为 0，范围 0..numberOfPages-1
@property (nonatomic, assign) NSInteger currentPage;

/// 如果只有一页，是否隐藏指示器，默认 NO
@property (nonatomic, assign) BOOL hidesForSinglePage;

/// 指示器间距，控制各个指示器之间的距离
@property (nonatomic, assign) CGFloat pageIndicatorSpacing;

/// 内容内边距，左右上下的间距，用于控制指示器位置
@property (nonatomic, assign) UIEdgeInsets contentInset;

/// 控件的实际内容大小，自动计算，返回 CGSize
@property (nonatomic, assign, readonly) CGSize contentSize;

/// 页面指示器的颜色，未选中时的颜色
@property (nullable, nonatomic, strong) UIColor *pageIndicatorTintColor;

/// 当前页指示器的颜色，选中页的颜色
@property (nullable, nonatomic, strong) UIColor *currentPageIndicatorTintColor;

/// 页面指示器的图片（用于替代颜色）
@property (nullable, nonatomic, strong) UIImage *pageIndicatorImage;

/// 当前页指示器的图片（用于替代颜色）
@property (nullable, nonatomic, strong) UIImage *currentPageIndicatorImage;

/// 页面指示器的图片内容模式，默认 UIViewContentModeCenter
@property (nonatomic, assign) UIViewContentMode indicatorImageContentMode;

/// 页面指示器的尺寸，默认 (8, 8)
@property (nonatomic, assign) CGSize pageIndicatorSize;

/// 当前页指示器的尺寸，默认与 pageIndicatorSize 相同
@property (nonatomic, assign) CGSize currentPageIndicatorSize;

/// 页面切换时的动画持续时间，默认 0.3 秒
@property (nonatomic, assign) CGFloat animateDuration;

/// 设置当前页数，并且可以选择是否启用动画效果
/// @param currentPage 当前页数
/// @param animate 是否启用动画效果
- (void)setCurrentPage:(NSInteger)currentPage animate:(BOOL)animate;

@end

NS_ASSUME_NONNULL_END
