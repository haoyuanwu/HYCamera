//
//  ViewController.m
//  HYCamera
//
//  Created by wuhaoyuan on 2016/9/28.
//  Copyright © 2016年 HYCamera. All rights reserved.
//

#import "ViewController.h"
#import "HYCameraViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.text = @"点击屏幕弹出照相机";
    [self.view addSubview:label];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    HYCameraViewController *camera = [[HYCameraViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:camera];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
