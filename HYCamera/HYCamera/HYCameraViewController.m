//
//  HYCameraViewController.m
//  pz
//
//  Created by wuhaoyuan on 16/6/27.
//  Copyright © 2016年 HYpz. All rights reserved.
//

#import "HYCameraViewController.h"

@protocol HYCameraImageViewDelegate <NSObject>

- (void)chooseImage:(UIImage *)image;

@end

@interface HYCameraImageView : UIView

@property(nonatomic,strong) UIImageView *imageV;

@property(nonatomic,strong) id<HYCameraImageViewDelegate> delegate;

@end

@implementation HYCameraImageView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        _imageV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _imageV.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageV];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 40, self.frame.size.width, 40)];
        view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self addSubview:view];
        
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(10, 0, 80, 40);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:cancelBtn];
        
        UIButton *chooseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        chooseBtn.frame = CGRectMake(frame.size.width - 80, 0, 80, 40);
        [chooseBtn setTitle:@"选取" forState:UIControlStateNormal];
        [chooseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [chooseBtn addTarget:self action:@selector(choose) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:chooseBtn];
        
    }
    return self;
}

/**
 *  选择图片
 */
- (void)choose{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chooseImage:)]) {
        [self.delegate chooseImage:_imageV.image];
    }
    self.hidden = YES;
}

- (void)cancel{
    self.hidden = YES;
}

@end



@interface HYCameraViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,HYCameraImageViewDelegate>
{
    HYCameraImageView *cameraView;
}

@property (nonatomic, assign) BOOL isUsingFrontFacingCamera;

@property (nonatomic, strong) UIView *bgView;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 闪光灯
 */
@property (nonatomic, strong) AVCaptureDevice *device;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 照片输出流
 */
@property (nonatomic, strong) AVCapturePhotoOutput* stillPhotoOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;
@end

@implementation HYCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    
    self.bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.bgView];
    
    [self initAVCaptureSession];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraBtn.frame = CGRectMake(self.view.frame.size.width/2 - 30, self.view.frame.size.height - 80, 60, 60);
    cameraBtn.layer.cornerRadius = cameraBtn.frame.size.width/2;
    cameraBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    [cameraBtn addTarget:self action:@selector(shutter) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    
    //闪光按钮
    UIButton *lampBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    lampBtn.frame = CGRectMake(self.view.frame.size.width - 60, self.view.frame.size.height - 80, 60, 60);
//    lampBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
    [lampBtn setImage:[UIImage imageNamed:@"kc_gbshanguang"] forState:UIControlStateNormal];
    [lampBtn setImage:[UIImage imageNamed:@"kc_shanguang"] forState:UIControlStateSelected];
    [lampBtn addTarget:self action:@selector(flasAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lampBtn];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(changeCamera)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipe];
    
    cameraView = [[HYCameraImageView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    cameraView.hidden = YES;
    cameraView.delegate = self;
    [self.view addSubview:cameraView];
}

//返回
- (void)goBack{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//确认按钮返回image
- (void)chooseImage:(UIImage *)image{
    if (self.delegate && [self.delegate respondsToSelector:@selector(HYCameraViewControllerChooseImage:chooseImage:)]) {
        [self.delegate HYCameraViewControllerChooseImage:self chooseImage:image];
    }
}

/**
 *  切换前置摄像头
 */
- (void)changeCamera{
    AVCaptureDevicePosition desiredPosition;
    if (self.isUsingFrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
    }
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
    
    NSArray *typeVideoArr;
    
    typeVideoArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    
    for (AVCaptureDevice *d in typeVideoArr) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
}

//闪光灯按钮的操作
- (void)flasAction:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    
    if ([self.device hasTorch] && [self.device hasFlash])
    {
        [self.device lockForConfiguration:nil];
        //闪光灯开
        if (sender.isSelected)
        {
            [self.device setFlashMode:AVCaptureFlashModeOn];
        }
        //闪光灯关
        else
        {
            [self.device setFlashMode:AVCaptureFlashModeOff];
        }
        //闪光灯自动，这里就不写了，可以自己尝试
        //[device setFlashMode:AVCaptureFlashModeAuto];
        [self.device unlockForConfiguration];
    }
}


-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

//拍照方法
- (void)shutter{
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput        connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:1];
    
    if (stillImageConnection) {
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer) {
                NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:jpegData];
                
                ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
                if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
                    if ([[UIDevice currentDevice].systemVersion floatValue] > 8.0) {
                        [self showAlertViewTitle:@"警告" message:@"您没有打开相册权限，无法保留事故证据，确定打开吗？" canceName:@"取消" otherName:@"确定" alertAction:^(UIAlertAction *action) {
                            if ([action.title isEqualToString:@"确定"]) {
                                NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                if (iOS10) {
                                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                }else{
                                    [[UIApplication sharedApplication] openURL:url ];
                                }
                                
                                
                            }
                        }];
                    }else{
                        [self showAlertViewTitle:@"警告" message:@"请在iPhonr的“设置-隐私-相机”中允许访问相册" canceName:@"确定" otherName:nil alertAction:nil];
                    }
                    
                    return ;
                }
                
                if (self.isUsingFrontFacingCamera) {
                    //操作图片方向
                    cameraView.imageV.image = [self flipHorizontal:image];
                }else{
                    cameraView.imageV.image = image;
                }
                cameraView.hidden = NO;
                if (self.delegate && [self.delegate respondsToSelector:@selector(HYCameraViewControllerChooseImage:chooseImage:)]) {
                    [self.delegate HYCameraViewControllerChooseImage:self chooseImage:image];
                }
                
//                [self.navigationController popViewControllerAnimated:YES];
//                [self dismissViewControllerAnimated:YES completion:nil];
                
                //存到相册
//                CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
//                                                                            imageDataSampleBuffer,
//                                                                            kCMAttachmentMode_ShouldPropagate);
//                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//                [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
//                    
//                }];
            }else{
                [self showAlertViewTitle:@"警告" message:@"没有生成图像，请正确使用相机！" canceName:nil otherName:nil alertAction:nil];
            }
        }];
        
    }else{
        if ([[UIDevice currentDevice].systemVersion floatValue] > 8.0) {
            [self showAlertViewTitle:@"警告" message:@"您没有打开相机权限，确定打开吗？" canceName:@"取消" otherName:@"确定" alertAction:^(UIAlertAction *action) {
                if ([action.title isEqualToString:@"确定"]) {
                    NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
        }else{
            [self showAlertViewTitle:@"警告" message:@"请在iPhonr的“设置-隐私-相机”中允许访问相机" canceName:@"确定" otherName:nil alertAction:nil];
        }
    }

}

- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [self.device lockForConfiguration:nil];
    //设置闪光灯为自动
    if (self.device.flashAvailable) {//先判断闪光灯是不是可用
        [self.device setFlashMode:AVCaptureFlashModeAuto];
    }
    [self.device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.bounds;
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
}


/**
 *  调整图片
 */
- (UIImage*)flipHorizontal:(UIImage *)aImage
{
    UIImage *image = nil;
    switch (aImage.imageOrientation) {
        case UIImageOrientationUp:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationUpMirrored];
            break;
        }
        case UIImageOrientationDown:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationDownMirrored];
            break;
        }
        case UIImageOrientationLeft:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationRightMirrored];
            break;
        }
        case UIImageOrientationRight:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationLeftMirrored];
            break;
        }
        case UIImageOrientationUpMirrored:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationUp];
            break;
        }
        case UIImageOrientationDownMirrored:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationDown];
            break;
        }
        case UIImageOrientationLeftMirrored:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationRight];
            break;
        }
        case UIImageOrientationRightMirrored:
        {
            image = [UIImage imageWithCGImage:aImage.CGImage scale:1 orientation:UIImageOrientationLeft];
            break;
        }
        default:
            break;
    }
    
    return image;
}

- (void)showAlertViewTitle:(NSString *)title message:(NSString *)message canceName:(NSString *)canceName otherName:(NSString *)otherName alertAction:(alertAction)alertAction{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleAlert)];
    if (canceName) {
        UIAlertAction *canceAction = [UIAlertAction actionWithTitle:canceName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            alertAction(action);
        }];
        [alertView addAction:canceAction];
    }
    if (otherName) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:otherName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            alertAction(action);
        }];
        [alertView addAction:action];
    }
    if (alertView.actions.count == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertView dismissViewControllerAnimated:YES completion:nil];
        });
    }
    
    [self presentViewController:alertView animated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
