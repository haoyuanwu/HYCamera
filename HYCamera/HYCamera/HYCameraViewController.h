//
//  HYCameraViewController.h
//  pz
//
//  Created by wuhaoyuan on 16/6/27.
//  Copyright © 2016年 HYpz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^alertAction)(UIAlertAction *action);
#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define iOS10 [[UIDevice currentDevice].systemVersion floatValue] >= 10.0
#define iOS9 [[UIDevice currentDevice].systemVersion floatValue] >= 9.0

@protocol HYCameraViewControllerDelegate <NSObject>

- (void)HYCameraViewControllerChooseImage:(UIViewController *)cameraViewController chooseImage:(UIImage *)image;

@end

@interface HYCameraViewController : UIViewController

@property (nonatomic, strong) id<HYCameraViewControllerDelegate> delegate;
@end
