//
//  ZHHLoopPagerViewLayout.m
//  ZHHLoopPagerView
//
//  Created by 桃色三岁 on 07/18/2021.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import "ZHHLoopPagerTransformLayout.h"

typedef NS_ENUM(NSUInteger, ZHHTransformLayoutItemDirection) {
    /// 项目在左侧
    ZHHTransformLayoutItemLeft,
    /// 项目在中间
    ZHHTransformLayoutItemCenter,
    /// 项目在右侧
    ZHHTransformLayoutItemRight,
};


@interface ZHHLoopPagerTransformLayout () {
    // 通过位字段（bit-fields）表示委托方法是否被实现
    struct {
        /// 是否实现了 applyTransformToAttributes 方法
        unsigned int applyTransformToAttributes   :1;
        /// 是否实现了 initializeTransformAttributes 方法
        unsigned int initializeTransformAttributes   :1;
    } _delegateFlags;
}

/// 标识是否应用了 applyTransformToAttributes 委托方法
@property (nonatomic, assign) BOOL applyTransformToAttributesDelegate;
@end


@interface ZHHLoopPagerViewLayout ()
/// 用于弱引用页面视图对象，避免循环引用
@property (nonatomic, weak) UIView *pageView;
@end


@implementation ZHHLoopPagerTransformLayout

- (instancetype)init {
    if (self = [super init]) {
        // 设置滚动方向为水平
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        // 设置滚动方向为水平
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

#pragma mark - getter setter

// 设置代理
- (void)setDelegate:(id<ZHHLoopPagerTransformLayoutDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        
        _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:initializeTransformAttributes:)];
        _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:applyTransformToAttributes:)];
    }
}

// 设置布局
- (void)setLayout:(ZHHLoopPagerViewLayout *)layout {
    if (_layout != layout) {
        _layout = layout;
        // 设置 pageView 为 collectionView
        _layout.pageView = self.collectionView;
        
        // 设置布局的 itemSize 和间距
        self.itemSize = _layout.itemSize;
        self.minimumInteritemSpacing = _layout.itemSpacing;
        self.minimumLineSpacing = _layout.itemSpacing;
    }
}

// 获取 itemSize
- (CGSize)itemSize {
    if (!_layout) {  // 如果 layout 为空，则返回父类的 itemSize
        return [super itemSize];
    }
    return _layout.itemSize;  // 返回布局的 itemSize
}

// 获取 minimumLineSpacing
- (CGFloat)minimumLineSpacing {
    if (!_layout) {  // 如果 layout 为空，则返回父类的 minimumLineSpacing
        return [super minimumLineSpacing];
    }
    return _layout.itemSpacing;  // 返回布局的 itemSpacing
}

// 获取 minimumInteritemSpacing
- (CGFloat)minimumInteritemSpacing {
    if (!_layout) {  // 如果 layout 为空，则返回父类的 minimumInteritemSpacing
        return [super minimumInteritemSpacing];
    }
    return _layout.itemSpacing;  // 返回布局的 itemSpacing
}

/// 根据传入的 centerX 值判断 item 在 collectionView 中的位置方向。
///
/// 该方法通过比较 item 的中心点与 collectionView 中心点的相对位置，返回该 item 是在左侧、中间还是右侧。
///
/// @param centerX item 在水平方向上的中心点位置。
/// @return 返回当前 item 所在的方向，可能是左侧、居中或右侧。
- (ZHHTransformLayoutItemDirection)directionWithCenterX:(CGFloat)centerX {
    // 默认方向为右侧
    ZHHTransformLayoutItemDirection direction = ZHHTransformLayoutItemRight;

    // 获取当前 collectionView 中心点的位置
    CGFloat contentCenterX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame) / 2;
    
    // 如果 item 的 centerX 与 collectionView 中心点差距小于 0.5，认为它在中间
    if (ABS(centerX - contentCenterX) < 0.5) {
        direction = ZHHTransformLayoutItemCenter;
    }
    // 如果 item 的 centerX 小于 collectionView 中心点，认为它在左边
    else if (centerX - contentCenterX < 0) {
        direction = ZHHTransformLayoutItemLeft;
    }
    
    // 返回判断后的方向
    return direction;
}

#pragma mark - layout
/// 判断 bounds 改变时是否需要重新布局
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    // 如果是普通布局，使用父类默认的行为；否则强制重新布局
    return _layout.layoutType == ZHHLoopPagerTransformLayoutNormal ? [super shouldInvalidateLayoutForBoundsChange:newBounds] : YES;
}

/// 获取指定区域内的所有布局属性并应用变换
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    // 如果需要自定义变换或布局类型不是普通布局，进行变换操作
    if (_delegateFlags.applyTransformToAttributes || _layout.layoutType != ZHHLoopPagerTransformLayoutNormal) {
        // 复制父类返回的布局属性数组，以便在不改变原数组的情况下修改
        NSArray *attributesArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        
        // 计算当前可见区域
        CGRect visibleRect = {self.collectionView.contentOffset, self.collectionView.bounds.size};
        
        // 遍历所有布局属性，判断是否需要应用变换
        for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
            // 如果布局项不在可见区域内，跳过
            if (!CGRectIntersectsRect(visibleRect, attributes.frame)) continue;
            
            // 如果代理方法存在，调用代理方法进行自定义变换；否则，按默认布局类型应用变换
            if (_delegateFlags.applyTransformToAttributes) {
                [_delegate pagerViewTransformLayout:self applyTransformToAttributes:attributes];
            } else {
                [self applyTransformToAttributes:attributes layoutType:_layout.layoutType];
            }
        }
        return attributesArray;
    }
    
    // 如果没有自定义变换，返回父类的布局属性
    return [super layoutAttributesForElementsInRect:rect];
}

/// 获取指定索引位置的布局属性，并根据布局类型或代理进行初始化变换
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 调用父类方法获取布局属性
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    // 如果代理方法存在，调用代理方法进行初始化变换
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate pagerViewTransformLayout:self initializeTransformAttributes:attributes];
    }
    // 如果布局类型不是普通布局，使用自定义变换初始化
    else if (_layout.layoutType != ZHHLoopPagerTransformLayoutNormal) {
        [self initializeTransformAttributes:attributes layoutType:_layout.layoutType];
    }
    
    // 返回经过处理后的布局属性
    return attributes;
}

#pragma mark - transform
/// 初始化布局属性的变换，根据布局类型决定应用的变换方式
- (void)initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(ZHHLoopPagerTransformLayoutType)layoutType {
    // 根据传入的布局类型，应用不同的变换逻辑
    switch (layoutType) {
        case ZHHLoopPagerTransformLayoutLinear:
            // 对属性应用线性变换：缩放和透明度
            [self applyLinearTransformToAttributes:attributes scale:_layout.minimumScale alpha:_layout.minimumAlpha];
            break;
            
        case ZHHLoopPagerTransformLayoutCoverflow:
        {
            // 对属性应用Coverflow效果：旋转角度和透明度
            [self applyCoverflowTransformToAttributes:attributes angle:_layout.maximumAngle alpha:_layout.minimumAlpha];
            break;
        }
            
        default:
            // 默认情况下不进行任何变换
            break;
    }
}

/// 应用变换到布局属性，具体的变换类型根据布局类型决定
- (void)applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(ZHHLoopPagerTransformLayoutType)layoutType {
    // 根据布局类型选择对应的变换方式
    switch (layoutType) {
        case ZHHLoopPagerTransformLayoutLinear:
            // 应用线性变换（例如缩放、透明度调整）
            [self applyLinearTransformToAttributes:attributes];
            break;
            
        case ZHHLoopPagerTransformLayoutCoverflow:
            // 应用Coverflow变换（例如旋转、透明度调整）
            [self applyCoverflowTransformToAttributes:attributes];
            break;
            
        default:
            // 默认不进行任何变换
            break;
    }
}

#pragma mark - LinearTransform

/// 应用线性变换（缩放、透明度调整）到布局属性
- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    // 获取当前集合视图的宽度
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    // 如果宽度无效，则不进行变换
    if (collectionViewWidth <= 0) {
        return;
    }
    
    // 计算集合视图的中心点X坐标
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth/2;
    // 计算当前单元格与集合视图中心点X坐标的距离
    CGFloat delta = ABS(attributes.center.x - centetX);
    
    // 根据距离中心点的偏差计算缩放比例和透明度，确保最小值不低于指定阈值
    CGFloat scale = MAX(1 - delta/collectionViewWidth*_layout.rateOfChange, _layout.minimumScale);
    CGFloat alpha = MAX(1 - delta/collectionViewWidth, _layout.minimumAlpha);
    
    // 应用线性变换
    [self applyLinearTransformToAttributes:attributes scale:scale alpha:alpha];
}

/// 应用具体的线性变换（缩放和透明度调整）
- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes scale:(CGFloat)scale alpha:(CGFloat)alpha {
    // 创建缩放变换
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    
    // 如果需要调整间距（滚动时）
    if (_layout.adjustSpacingWhenScroling) {
        // 获取当前单元格相对集合视图中心点的方向
        ZHHTransformLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
        
        CGFloat translate = 0;
        // 根据方向调整偏移量
        switch (direction) {
            case ZHHTransformLayoutItemLeft:
                // 左侧项向右偏移
                translate = 1.15 * attributes.size.width * (1 - scale) / 2;
                break;
            case ZHHTransformLayoutItemRight:
                // 右侧项向左偏移
                translate = -1.15 * attributes.size.width * (1 - scale) / 2;
                break;
            default:
                // 中心项保持默认大小
                scale = 1.0;
                alpha = 1.0;
                break;
        }
        // 应用偏移量
        transform = CGAffineTransformTranslate(transform, translate, 0);
    }
    
    // 设置最终的变换和透明度
    attributes.transform = transform;
    attributes.alpha = alpha;
}

#pragma mark - CoverflowTransform

/// 应用Coverflow效果变换到布局属性
- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    // 获取当前集合视图的宽度
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    // 如果宽度无效，则不进行变换
    if (collectionViewWidth <= 0) {
        return;
    }
    
    // 计算集合视图中心点X坐标
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth / 2;
    // 计算当前单元格与集合视图中心点X坐标的距离
    CGFloat delta = ABS(attributes.center.x - centetX);
    
    // 根据距离中心点的偏差计算旋转角度（最大角度限制）
    CGFloat angle = MIN(delta / collectionViewWidth * (1 - _layout.rateOfChange), _layout.maximumAngle);
    // 计算透明度，确保最小值不低于指定阈值
    CGFloat alpha = MAX(1 - delta / collectionViewWidth, _layout.minimumAlpha);
    
    // 应用Coverflow效果变换
    [self applyCoverflowTransformToAttributes:attributes angle:angle alpha:alpha];
}

/// 应用具体的Coverflow效果变换（旋转、透明度调整）
- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes angle:(CGFloat)angle alpha:(CGFloat)alpha {
    // 获取当前单元格相对集合视图中心点的方向
    ZHHTransformLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
    
    // 初始化3D变换
    CATransform3D transform3D = CATransform3DIdentity;
    // 设置3D效果的透视
    transform3D.m34 = -0.002;
    
    // 用于控制元素平移的值
    CGFloat translate = 0;
    switch (direction) {
        case ZHHTransformLayoutItemLeft:
            // 左侧项根据角度计算平移值
            translate = (1 - cos(angle * 1.2 * M_PI)) * attributes.size.width;
            break;
        case ZHHTransformLayoutItemRight:
            // 右侧项根据角度计算平移值，并且反转角度
            translate = -(1 - cos(angle * 1.2 * M_PI)) * attributes.size.width;
            angle = -angle;
            break;
        default:
            // 中心项不进行旋转，透明度恢复为1
            angle = 0;
            alpha = 1;
            break;
    }
    
    // 应用旋转变换
    transform3D = CATransform3DRotate(transform3D, M_PI * angle, 0, 1, 0);
    
    // 如果需要调整间距（滚动时），则进行平移变换
    if (_layout.adjustSpacingWhenScroling) {
        transform3D = CATransform3DTranslate(transform3D, translate, 0, 0);
    }
    
    // 设置最终的3D变换
    attributes.transform3D = transform3D;
    // 设置透明度
    attributes.alpha = alpha;
}
@end


@implementation ZHHLoopPagerViewLayout

// 初始化方法，设置一些默认值
- (instancetype)init {
    if (self = [super init]) {
        _itemVerticalCenter = YES;  // 默认垂直居中
        _minimumScale = 0.8;  // 默认最小缩放比例
        _minimumAlpha = 1.0;  // 默认最小透明度
        _maximumAngle = 0.2;  // 默认最大旋转角度
        _rateOfChange = 0.4;  // 默认缩放与旋转的变化率
        _adjustSpacingWhenScroling = YES;  // 默认滚动时调整间距
    }
    return self;
}

#pragma mark - getter

// 获取单一段落的边距
- (UIEdgeInsets)onlyOneSectionInset {
    // 计算左右边距
    CGFloat leftSpace = _pageView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.left;
    CGFloat rightSpace = _pageView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.right;
    
    // 如果垂直居中，计算上下边距
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, leftSpace, verticalSpace, rightSpace);  // 上下左右边距
    }
    return UIEdgeInsetsMake(_sectionInset.top, leftSpace, _sectionInset.bottom, rightSpace);  // 垂直居中不做处理时，直接返回原始边距
}

// 获取第一个段落的边距
- (UIEdgeInsets)firstSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, _sectionInset.left, verticalSpace, _itemSpacing);  // 上下居中，左右边距保持原样
    }
    return UIEdgeInsetsMake(_sectionInset.top, _sectionInset.left, _sectionInset.bottom, _itemSpacing);  // 垂直居中不做处理时，返回原始边距
}

// 获取最后一个段落的边距
- (UIEdgeInsets)lastSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _sectionInset.right);  // 上下居中，左右边距保持原样
    }
    return UIEdgeInsetsMake(_sectionInset.top, 0, _sectionInset.bottom, _sectionInset.right);  // 垂直居中不做处理时，返回原始边距
}

// 获取中间段落的边距
- (UIEdgeInsets)middleSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _itemSpacing);  // 上下居中，左右边距保持原样
    }
    return _sectionInset;  // 垂直居中不做处理时，返回原始边距
}

@end
