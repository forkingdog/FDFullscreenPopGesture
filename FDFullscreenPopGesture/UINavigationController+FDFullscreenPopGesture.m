// The MIT License (MIT)
//
// Copyright (c) 2015-2016 forkingdog ( https://github.com/forkingdog )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "UINavigationController+FDFullscreenPopGesture.h"
#import <objc/runtime.h>

@interface _FDFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation _FDFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    // Ignore when the active view controller doesn't allow interactive pop.
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.fd_interactivePopDisabled) {
        return NO;
    }
    
    // Ignore when the beginning location is beyond max allowed initial distance to left edge.
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.fd_interactivePopMaxAllowedInitialDistanceToLeftEdge;
    if (maxAllowedInitialDistance > 0 && beginningLocation.x > maxAllowedInitialDistance) {
        return NO;
    }

    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    return YES;
}

@end

typedef void (^_FDViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (FDFullscreenPopGesturePrivate)

@property (nonatomic, copy) _FDViewControllerWillAppearInjectBlock fd_willAppearInjectBlock;

@end

@implementation UIViewController (FDFullscreenPopGesturePrivate)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(fd_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)fd_viewWillAppear:(BOOL)animated
{
    // Forward to primary implementation.
    [self fd_viewWillAppear:animated];
    
    if (self.fd_willAppearInjectBlock) {
        self.fd_willAppearInjectBlock(self, animated);
    }
}

- (_FDViewControllerWillAppearInjectBlock)fd_willAppearInjectBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFd_willAppearInjectBlock:(_FDViewControllerWillAppearInjectBlock)block
{
    objc_setAssociatedObject(self, @selector(fd_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (FDFullscreenPopGesture)

+ (void)load
{
    // Inject "-pushViewController:animated:"
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(pushViewController:animated:);
        SEL swizzledSelector = @selector(fd_pushViewController:animated:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)fd_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ( [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ) {
        if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.fd_fullscreenPopGestureRecognizer]) {
            
            // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
            [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.fd_fullscreenPopGestureRecognizer];
            
            // Forward the gesture events to the private handler of the onboard gesture recognizer.
            NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
            id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
            SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
            self.fd_fullscreenPopGestureRecognizer.delegate = self.fd_popGestureRecognizerDelegate;
            [self.fd_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
            
            // Disable the onboard gesture recognizer.
            self.interactivePopGestureRecognizer.enabled = NO;
        }
        
        // Handle perferred navigation bar appearance.
        [self fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    } else {
        [viewController.view addGestureRecognizer:viewController.fd_swipeRightGesture];
    }
    
    // Forward to primary implementation.
    if (![self.viewControllers containsObject:viewController]) {
        [self fd_pushViewController:viewController animated:animated];
    }
}

- (void)fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    if (!self.fd_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    _FDViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.fd_prefersNavigationBarHidden animated:animated];
        }
    };
    
    // Setup will appear inject block to appearing view controller.
    // Setup disappearing view controller as well, because not every view controller is added into
    // stack by pushing, maybe by "-setViewControllers:".
    appearingViewController.fd_willAppearInjectBlock = block;
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.fd_willAppearInjectBlock) {
        disappearingViewController.fd_willAppearInjectBlock = block;
    }
}

- (_FDFullscreenPopGestureRecognizerDelegate *)fd_popGestureRecognizerDelegate
{
    _FDFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);

    if (!delegate) {
        delegate = [[_FDFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)fd_fullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);

    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (BOOL)fd_viewControllerBasedNavigationBarAppearanceEnabled
{
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.fd_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setFd_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled
{
    SEL key = @selector(fd_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fd_enableSwipeRight
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_enableSwipeRight:(BOOL)enable
{
    objc_setAssociatedObject(self, @selector(fd_enableSwipeRight), @(enable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (FDFullscreenPopGesture)

- (BOOL)fd_interactivePopDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_interactivePopDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(fd_interactivePopDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fd_prefersNavigationBarHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_prefersNavigationBarHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fd_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fd_interactivePopMaxAllowedInitialDistanceToLeftEdge
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setFd_interactivePopMaxAllowedInitialDistanceToLeftEdge:(CGFloat)distance
{
    SEL key = @selector(fd_interactivePopMaxAllowedInitialDistanceToLeftEdge);
    objc_setAssociatedObject(self, key, @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UISwipeGestureRecognizer *)fd_swipeRightGesture
{
    UISwipeGestureRecognizer *swipeRightGesture = objc_getAssociatedObject(self, _cmd);
    if (!swipeRightGesture) {
        swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(fd_swipeRight:)];
        [swipeRightGesture setDirection:UISwipeGestureRecognizerDirectionRight];
        
        objc_setAssociatedObject(self, _cmd, swipeRightGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return swipeRightGesture;
}

- (BOOL)fd_enableSwipeRight
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFd_enableSwipeRight:(BOOL)enable
{
    objc_setAssociatedObject(self, @selector(fd_enableSwipeRight), @(enable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - action

- (void)fd_swipeRight:(UISwipeGestureRecognizer*)gesture
{
    if (!self.navigationController.fd_enableSwipeRight) {
        return;
    }
    if (!self.fd_enableSwipeRight) {
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
