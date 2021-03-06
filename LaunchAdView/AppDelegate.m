//
//  AppDelegate.m
//  LaunchAdView
//
//  Created by yesdgq on 2017/6/8.
//  Copyright © 2017年 yesdgq. All rights reserved.
//

#import "AppDelegate.h"
#import "LaunchAdView.h"

@interface AppDelegate ()

@property (nonatomic, strong) LaunchAdView *launchAdView;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setLaunchAdvertisement
{
    [self.window makeKeyAndVisible];
    
    NSString *str = nil;
    str = @"http://img.shenghuozhe.net/shz/2016/05/07/750w_1224h_043751462609867.jpg";
    str = @"http://192.167.1.6:15414//multimedia/image/EPOSIDE/2017/05/24/2017_05_24_10_05_27_590.jpg";
    
    self.launchAdView = [[LaunchAdView alloc] init];
    self.launchAdView.imageURL = @"";
    self.launchAdView.getLaunchImageAdViewType(FullScreenAdType);
    // 各种点击事件的回调
    self.launchAdView.clickBlock = ^(clickType type){
        switch (type) {
            case clickAdType:
                // 点击广告回调
                NSLog(@"点击广告回调");
                break;
            case skipAdType:
                NSLog(@"点击跳过回调");
                break;
            case overtimeAdType:
                NSLog(@"倒计时完成后的回调");
                break;
            default:
                break;
        }
    };
    
    [self.window addSubview: self.launchAdView];
}


@end
