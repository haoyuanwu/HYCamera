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
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
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
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
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
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:jpegData];
        if (self.isUsingFrontFacingCamera) {
            //操作图片方向
            cameraView.imageV.image = [self flipHorizontal:image];
        }else{
            cameraView.imageV.image = image;
        }
        
        cameraView.hidden = NO;
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
        
    }];
}

- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
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
    self.bgView.layer.masksToBounds = YES;
    [self.bgView.layer addSublayer:self.previewLayer];
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