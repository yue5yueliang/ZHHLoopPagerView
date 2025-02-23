//
//  ZHHLoopPagerViewCell.m
//  ZHHLoopPagerView_Example
//
//  Created by 桃色三岁 on 2025/2/23.
//  Copyright © 2025 136769890@qq.com. All rights reserved.
//

#import "ZHHLoopPagerViewCell.h"

@interface ZHHLoopPagerViewCell ()
@property (nonatomic, weak) UILabel *label;
@end

@implementation ZHHLoopPagerViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addLabel];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
        [self addLabel];
    }
    return self;
}


- (void)addLabel {
    UILabel *label = [[UILabel alloc]init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:18];
    [self addSubview:label];
    _label = label;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = self.bounds;
}
@end
