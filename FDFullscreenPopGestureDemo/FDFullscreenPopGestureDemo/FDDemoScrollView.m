//
//  FDDemoScrollView.m
//  FDFullscreenPopGestureDemo
//
//  Created by afantree on 2016/10/13.
//  Copyright © 2016年 forkingdog. All rights reserved.
//

#import "FDDemoScrollView.h"

@implementation FDDemoScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.contentOffset.x <= 0) {
        if ([otherGestureRecognizer.delegate isKindOfClass:NSClassFromString(@"_FDFullscreenPopGestureRecognizerDelegate")]) {
            return YES;
        }
    }
    return NO;
}

@end
