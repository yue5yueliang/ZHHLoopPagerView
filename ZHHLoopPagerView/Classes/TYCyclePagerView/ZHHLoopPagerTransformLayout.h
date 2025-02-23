//
//  ZHHLoopPagerViewLayout.h
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 定义循环翻页的布局类型
typedef NS_ENUM(NSUInteger, ZHHLoopPagerTransformLayoutType) {
    /// 普通布局
    ZHHLoopPagerTransformLayoutNormal,
    /// 线性布局
    ZHHLoopPagerTransformLayoutLinear,
    /// 叠加布局（Coverflow效果）
    ZHHLoopPagerTransformLayoutCoverflow
};

// ZHHLoopPagerTransformLayout的代理协议
@class ZHHLoopPagerTransformLayout;

@protocol ZHHLoopPagerTransformLayoutDelegate <NSObject>

// 初始化布局属性
// 在分页视图布局初始化时调用，设置初始的布局属性（如位置、尺寸等）
- (void)pagerViewTransformLayout:(ZHHLoopPagerTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

// 应用布局属性
// 在每次更新布局时调用，应用当前的变换效果（如缩放、旋转等）到布局属性上
- (void)pagerViewTransformLayout:(ZHHLoopPagerTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end


@interface ZHHLoopPagerViewLayout : NSObject

/// 每个项的尺寸
@property (nonatomic, assign) CGSize itemSize;

/// 每个项之间的间距
@property (nonatomic, assign) CGFloat itemSpacing;

/// section的内边距
@property (nonatomic, assign) UIEdgeInsets sectionInset;

/// 布局类型，决定分页视图的显示方式
@property (nonatomic, assign) ZHHLoopPagerTransformLayoutType layoutType;

/// 最小缩放比例（默认值：0.8）
@property (nonatomic, assign) CGFloat minimumScale;

/// 最小透明度（默认值：1.0）
@property (nonatomic, assign) CGFloat minimumAlpha;

/// 最大旋转角度，角度的变化百分比（默认值：0.2）
@property (nonatomic, assign) CGFloat maximumAngle;

/// 是否支持无限循环（即左右滑动超出边界时会跳到另一端）
@property (nonatomic, assign) BOOL isInfiniteLoop;

/// 缩放和旋转效果的变化速率
@property (nonatomic, assign) CGFloat rateOfChange;

/// 是否在滚动时自动调整项之间的间距
@property (nonatomic, assign) BOOL adjustSpacingWhenScroling;

/// 是否启用垂直居中的效果，调整项的垂直对齐方式
@property (nonatomic, assign) BOOL itemVerticalCenter;

/// 是否启用第一个和最后一个项水平居中的效果，仅在 `isInfiniteLoop` 为 NO 时生效
@property (nonatomic, assign) BOOL itemHorizontalCenter;

/// 只包含一个 section 时的内边距
@property (nonatomic, assign, readonly) UIEdgeInsets onlyOneSectionInset;

/// 第一个 section 的内边距
@property (nonatomic, assign, readonly) UIEdgeInsets firstSectionInset;

/// 最后一个 section 的内边距
@property (nonatomic, assign, readonly) UIEdgeInsets lastSectionInset;

/// 中间 section 的内边距
@property (nonatomic, assign, readonly) UIEdgeInsets middleSectionInset;

@end


@interface ZHHLoopPagerTransformLayout : UICollectionViewFlowLayout

// 自定义分页视图布局配置对象，包含了分页视图的各种布局设置
@property (nonatomic, strong) ZHHLoopPagerViewLayout *layout;

// 布局代理，提供初始化和应用布局属性的回调
@property (nonatomic, weak, nullable) id<ZHHLoopPagerTransformLayoutDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
