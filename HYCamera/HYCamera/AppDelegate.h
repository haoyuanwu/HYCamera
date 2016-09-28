//
//  AppDelegate.h
//  HYCamera
//
//  Created by wuhaoyuan on 2016/9/28.
//  Copyright © 2016年 HYCamera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

