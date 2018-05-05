//
//  FDDemoCompletionDistanceVC.m
//  FDFullscreenPopGestureDemo
//
//  Created by Cosmo Julis on 2018/5/5.
//  Copyright © 2018年 forkingdog. All rights reserved.
//

#import "FDDemoCompletionDistanceVC.h"
#import "UINavigationController+FDFullscreenPopGesture.h"

@interface FDDemoCompletionDistanceVC ()

@end

@implementation FDDemoCompletionDistanceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fd_interactivePopTransitionCompletionDistance = 44;
}

@end
