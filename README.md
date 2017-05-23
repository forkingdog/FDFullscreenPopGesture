# FDFullscreenPopGesture
An UINavigationController's category to enable fullscreen pop gesture in an iOS7+ system style with AOP.

# Overview

![snapshot](https://raw.githubusercontent.com/forkingdog/FDFullscreenPopGesture/master/Snapshots/snapshot0.gif)

这个扩展来自 @J_雨 同学的这个很天才的思路，他的文章地址：[http://www.jianshu.com/p/d39f7d22db6c](http://www.jianshu.com/p/d39f7d22db6c)

# Usage

**AOP**, just add 2 files and **no need** for any setups, all navigation controllers will be able to use fullscreen pop gesture automatically.  

To disable this pop gesture of a navigation controller:  

``` objc
navigationController.fd_fullscreenPopGestureRecognizer.enabled = NO;
```

To disable this pop gesture of a view controller:  

``` objc
viewController.fd_interactivePopDisabled = YES;
```

Require at least iOS **7.0**.

# View Controller Based Navigation Bar Appearance

It handles navigation bar transition properly when using fullscreen gesture to push or pop a view controller:  

- with bar -> without bar
- without bar -> with bar
- without bar -> without bar

![snapshot with bar states](https://raw.githubusercontent.com/forkingdog/FDFullscreenPopGesture/master/Snapshots/snapshot1.gif)

This opmiziation is enabled by default, from now on you don't need to call **UINavigationController**'s `-setNavigationBarHidden:animated:` method, instead, use view controller's specific API to hide its bar:  

``` objc
- (void)viewDidLoad {
    [super viewDidLoad];
    self.fd_prefersNavigationBarHidden = NO;
}
```

And this property is **NO** by default.

# View Controller With ScrollView

If you want to use fullscreen pop gesture in ViewController with scrollView or subclass of scrollView , you should customize the scrollView or subclass of scrollView and overload the `gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` method . like this:

``` objc
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.contentOffset.x <= 0) {
        if ([otherGestureRecognizer.delegate isKindOfClass:NSClassFromString(@"_FDFullscreenPopGestureRecognizerDelegate")]) {
            return YES;
        }
    }
    return NO;
}
```

# Installation

Use CocoaPods  

``` ruby
pod 'FDFullscreenPopGesture', '1.1'
```
# Release Notes

**1.1** - View controller based navigation bar appearance and transition.  
**1.0** - Fullscreen pop gesture.  

# License  
MIT
