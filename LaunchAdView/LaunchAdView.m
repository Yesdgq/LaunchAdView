//
//  LaunchAdView.m
//  LaunchAdView
//
//  Created by yesdgq on 2017/6/8.
//  Copyright © 2017年 yesdgq. All rights reserved.
//

#import "LaunchAdView.h"
#import "Masonry.h"
#import "DACircularProgressView.h"

//AdLaunchType state = AdLaunchProgressType;
static NSString *const adImageUrl = @"adImageUrl";
static NSString *const adImageName = @"adImageName";

#define DONG_UserDefaults [NSUserDefaults standardUserDefaults]
#define kMainScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define kMainScreenHeight   [[UIScreen mainScreen] bounds].size.height

@interface LaunchAdView ()

/** 广告背景 */
@property (nonatomic, strong) UIView *adBackground;
/** 跳过按钮 */
@property (nonatomic, strong) UIButton *skipBtn;

@property (nonatomic, strong) NSTimer *countDownTimer;
/** 点击标识 */
@property (strong, nonatomic) NSString *clickId;
/** 本地图片名字 */
@property (nonatomic, copy) NSString *localAdImgName;

@end

@implementation LaunchAdView

#pragma mark - override

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    return self;
}

#pragma mark - 获取广告类型

- (void (^)(AdType adType))getLaunchImageAdViewType
{
    __weak typeof(self) weakSelf = self;
    return ^(AdType adType){
        [weakSelf addLaunchImageAdView:adType];
    };
}

- (void)addLaunchImageAdView:(AdType)adType
{
    [self displayCachedAd:adType]; // 显示广告图片
    
    [self addSkipButton]; // 跳过按钮
    
}

#pragma mark - 指定宽度按比例缩放

- (UIImage *)imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if (CGSizeEqualToSize(imageSize, size) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor;
        } else {
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if (widthFactor > heightFactor) {
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            
        } else if(widthFactor < heightFactor) {
            
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    //    UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)setLocalAdImgName:(NSString *)localAdImgName
{
    _localAdImgName = localAdImgName;
    if (_localAdImgName) {
        if ([_localAdImgName rangeOfString:@".gif"].location  != NSNotFound ) {
            _localAdImgName  = [_localAdImgName stringByReplacingOccurrencesOfString:@".gif" withString:@""];
            NSData *gifData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:_localAdImgName ofType:@"gif"]];
            UIWebView *webView = [[UIWebView alloc] initWithFrame:self.adImageView.frame];
            webView.backgroundColor = [UIColor clearColor];
            webView.scalesPageToFit = YES;
            webView.scrollView.scrollEnabled = NO;
            [webView loadData:gifData MIMEType:@"image/gif" textEncodingName:@"" baseURL:[NSURL URLWithString:@""]];
            UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            clearBtn.frame = webView.frame;
            clearBtn.backgroundColor = [UIColor clearColor];
            [clearBtn addTarget:self action:@selector(removeAdvertView) forControlEvents:UIControlEventTouchUpInside];
            [webView addSubview:clearBtn];
            [self.adImageView addSubview:webView];
            [self.adImageView bringSubviewToFront:_skipBtn];
        } else {
            self.adImageView.image = [UIImage imageNamed:_localAdImgName];
        }
    }
}

#pragma mark - 获取本地图片缓存，如果没有广告结束

- (void) displayCachedAd:(AdType)adType
{
    // 1.判断沙盒中是否存在广告图片，如果存在，直接显示
    NSString *filePath = [self getFilePathWithImageName:[DONG_UserDefaults valueForKey:adImageName]];
    
    BOOL isExist = [self isFileExistWithFilePath:filePath];
    if (isExist) { // 图片存在
        [self showImage:adType];
    } else {
        self.hidden = YES;
    }
    // 2.无论沙盒中是否存在广告图片，都需要重新调用广告接口，判断广告是否更新
    [self requestAdvertisementData];
}

#pragma mark - 展示图片

- (void)showImage:(AdType)adType
{
    if (adType == FullScreenAdType) {
        self.adImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    } else {
        [self addSubview: self.adBackground]; // 背景
        self.adImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight - kMainScreenWidth/3)];
    }
    NSString *filePath = [self getFilePathWithImageName:[DONG_UserDefaults valueForKey:adImageName]];
    [self.adImageView setImage:[UIImage imageWithContentsOfFile:filePath]];
    [self.adImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickAd)];
    [self.adImageView addGestureRecognizer:singleTap];
    [self addSubview: _adImageView];
    
    //获取启动图片
    //    CGSize viewSize = [UIApplication sharedApplication].delegate.window.bounds.size;
    //    //横屏请设置成 @"Landscape"
    //    NSString *viewOrientation = @"Portrait";
    //    __block NSString *launchImageName = nil;
    //    NSArray* imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    //    [imagesDict enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //        CGSize imageSize = CGSizeFromString(obj[@"UILaunchImageSize"]);
    //        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:obj[@"UILaunchImageOrientation"]])
    //        {
    //            launchImageName = obj[@"UILaunchImageName"];
    //        }
    //    }];
    //    UIImage * launchImage = [UIImage imageNamed:launchImageName];
    //    self.backgroundColor = [UIColor colorWithPatternImage:launchImage];
    
    self.frame = [UIScreen mainScreen].bounds;
}

#pragma mark - 下载图片

- (void) requestAdvertisementData
{
    // 获取图片名:43-130P5122Z60-50.jpg
    NSArray *stringArr = [self.imageURL componentsSeparatedByString:@"/"];
    NSString *imageName = stringArr.lastObject;
    
    // 拼接沙盒路径
    NSString *filePath = [self getFilePathWithImageName:imageName];
    NSLog(@"filePath-->%@", filePath);
    BOOL isExist = [self isFileExistWithFilePath:filePath];
    if (!isExist){ // 如果该图片不存在，则删除老图片，下载新图片
        [self downloadAdImageWithUrl:self.imageURL imageName:imageName];
    }
}

- (void)downloadAdImageWithUrl:(NSString *)imageUrl imageName:(NSString *)imageName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        
        NSString *filePath = [self getFilePathWithImageName:imageName]; // 保存文件的名称
        
        if ([UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES]) {// 保存成功
            NSLog(@"广告下载并保存成功！");
            [self deleteOldImage];
            [DONG_UserDefaults setValue:imageName forKey:adImageName];
            [DONG_UserDefaults synchronize];
            // 如果有广告链接，将广告链接也保存下来
        } else {
            NSLog(@"广告下载失败！");
            [self deleteOldImage];
            [DONG_UserDefaults setValue:imageName forKey:adImageName];
            [DONG_UserDefaults synchronize];
        }
        
    });
}

#pragma mark - 删除旧图片

- (void)deleteOldImage
{
    NSString *imageName = [DONG_UserDefaults valueForKey:adImageName];
    if (imageName) {
        NSString *filePath = [self getFilePathWithImageName:imageName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark - 添加跳过按钮

- (void)addSkipButton
{
    if (self.showtime == 0) {
        self.showtime = 5;
    }
    self.skipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.skipBtn.frame = CGRectMake(kMainScreenWidth - 70, 20, 60, 30);
    self.skipBtn.backgroundColor = [UIColor brownColor];
    self.skipBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.skipBtn setTitle:[NSString stringWithFormat:@"%@ | 跳过",@(_showtime)] forState:UIControlStateNormal];
    [self.skipBtn addTarget:self action:@selector(skipBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.adImageView addSubview:self.skipBtn];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.skipBtn.bounds byRoundingCorners:UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii:CGSizeMake(15, 15)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.skipBtn.bounds;
    maskLayer.path = maskPath.CGPath;
    self.skipBtn.layer.mask = maskLayer;
    _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_countDownTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - 点击事件

// 点击跳过按钮
- (void)skipBtnClick
{
    _clickId = @"2";
    [self removeAdvertView];
}

// 点击广告
- (void)clickAd
{
    if ([self.delegate respondsToSelector:@selector(clickAdvertisement:)]) {
        [self.delegate clickAdvertisement:self];
    }
    
    _clickId = @"1";
    [self removeAdvertView];
}

#pragma mark - 移除广告

- (void)removeAdvertView
{
    if ([_clickId integerValue] == 1) {
        if (self.clickBlock) { //点击广告
            self.clickBlock(clickAdType);
        }
    } else if([_clickId integerValue] == 2) {
        if (self.clickBlock) { //点击跳过
            self.clickBlock(skipAdType);
        }
    } else {
        if (self.clickBlock) {
            self.clickBlock(overtimeAdType);
        }
    }
    
    [_countDownTimer invalidate];
    _countDownTimer = nil;
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)countDown
{
    if (_showtime == 0) {
        [self removeAdvertView];
    } else {
        [self.skipBtn setTitle:[NSString stringWithFormat:@"%@ | 跳过",@(_showtime--)] forState:UIControlStateNormal];
    }
}


#pragma mark - 懒加载

- (UIView *)adBackground
{
    UIView *footerView = [[UIView alloc] initWithFrame: CGRectMake(0, kMainScreenHeight - kMainScreenWidth/3, kMainScreenWidth, kMainScreenWidth/3)];
    footerView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *slogan = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"KDTKLaunchSlogan_Content"]];
    [footerView addSubview: slogan];
    
    
    [slogan mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(footerView);
    }];
    
    UIView *view = [[UIView alloc] initWithFrame: [UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview: footerView];
    return view;
    
    return nil;
}

/**
 *  根据图片名拼接文件路径 Caches文件夹
 */
- (NSString *)getFilePathWithImageName:(NSString *)imageName
{
    if (imageName) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        return filePath;
    }
    return nil;
}

/**
 *  判断文件是否存在
 */
- (BOOL)isFileExistWithFilePath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = FALSE;
    return [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
}



//UIButton *showDetailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//[showDetailBtn setTitle:@"详情>>" forState:UIControlStateNormal];
//[showDetailBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//[showDetailBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//showDetailBtn.titleLabel.font = [UIFont systemFontOfSize:13];
//showDetailBtn.frame = CGRectMake(f.size.width - 70, 30, 60, 30);
//showDetailBtn.layer.borderColor = [UIColor whiteColor].CGColor;
//showDetailBtn.layer.borderWidth = 1.0f;
//showDetailBtn.layer.cornerRadius = 3.0f;
//[showDetailBtn addTarget:self action:@selector(showAdDetail:) forControlEvents:UIControlEventTouchUpInside];
//[v addSubview:showDetailBtn];



@end
