//
//  LaunchAdView.h
//  LaunchAdView
//
//  Created by yesdgq on 2017/6/8.
//  Copyright © 2017年 yesdgq. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LaunchAdView;

typedef enum {
    LogoAdType = 0, // 带logo的广告
    FullScreenAdType = 1, // 全屏的广告
} AdType;

typedef enum {
    skipAdType = 1, // 点击跳过
    clickAdType = 2, // 点击广告
    overtimeAdType = 3, // 倒计时完成跳过
} clickType;

typedef NS_ENUM (NSUInteger, AdLaunchType) {
    AdLaunchProgressType = 0,
    AdLaunchTimerType
};

typedef void (^AdClick) (const clickType);

@protocol LaunchAdViewDelegate <NSObject>

- (void)clickAdvertisement:(LaunchAdView *)launchView;

@end

@interface LaunchAdView : UIView

/** 广告图片 */
@property (nonatomic, strong) UIImageView *adImageView;
/** 倒计时总时长,默认5秒 */
@property (nonatomic, assign) NSInteger showtime;
/** 图片URL */
@property (nonatomic, strong) NSString *imageURL;

@property (nonatomic, weak) id<LaunchAdViewDelegate> delegate;
/** 点击回调 */
@property (nonatomic, copy) AdClick clickBlock;


/*
 *  adType 广告类型
 */
- (void (^)(AdType adType))getLaunchImageAdViewType;



@end
