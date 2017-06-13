//
//  UIViewController+ FDFullscreenPopGesture.swift
//  Swift3Project
//
//  Created by Yilei on 27/2/17.
//  Copyright © 2017 lionhylra.com. All rights reserved.
//

import UIKit
import ObjectiveC

public protocol FDProxyConvertible {}

extension FDProxyConvertible {
    public var fd: FDProxy<Self> {
        return FDProxy(base: self)
    }
}

extension UIViewController: FDProxyConvertible {}

public class FDProxy<T: FDProxyConvertible> {
    fileprivate let base: T
    fileprivate init(base: T) {
        self.base = base
    }
}

// MARK: - Associated Object(private) -

private var _fullscreenPopGestureRecognizerAssociationKey: UInt8 = 0
private var _viewControllerBasedNavigationBarAppearanceEnabledAssociationKey: UInt8 = 0

extension UINavigationController {
    
    
    
    fileprivate var _fullscreenPopGestureRecognizer: UIPanGestureRecognizer! {
        if let panGestureRecognizer = objc_getAssociatedObject(self, &_fullscreenPopGestureRecognizerAssociationKey) as? UIPanGestureRecognizer {
            return panGestureRecognizer
        }
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        objc_setAssociatedObject(self, &_fullscreenPopGestureRecognizerAssociationKey, pan, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return pan
        
    }
    
    
    
    fileprivate var _viewControllerBasedNavigationBarAppearanceEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &_viewControllerBasedNavigationBarAppearanceEnabledAssociationKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &_viewControllerBasedNavigationBarAppearanceEnabledAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


private var _interactivePopDisabledAssociationKey: UInt8 = 0
private var _prefersNavigationBarHiddenAssociationKey: UInt8 = 0
private var _interactivePopMaxAllowedInitialDistanceToLeftEdgeAssociationKey: UInt8 = 0

extension UIViewController {
    
    
    
    fileprivate var _interactivePopDisabled: Bool {
        get {
            return objc_getAssociatedObject(self, &_interactivePopDisabledAssociationKey) as? Bool ?? false
        }
        set {
            return objc_setAssociatedObject(self, &_interactivePopDisabledAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    
    fileprivate var _prefersNavigationBarHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &_prefersNavigationBarHiddenAssociationKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &_prefersNavigationBarHiddenAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    
    fileprivate var _interactivePopMaxAllowedInitialDistanceToLeftEdge: CGFloat {
        get {
            return objc_getAssociatedObject(self, &_interactivePopMaxAllowedInitialDistanceToLeftEdgeAssociationKey) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &_interactivePopMaxAllowedInitialDistanceToLeftEdgeAssociationKey, max(newValue, 0), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Public properties -

extension FDProxy where T: UINavigationController {
    
    /// The gesture recognizer that actually handles interactive pop.
    public var fullscreenPopGestureRecognizer: UIPanGestureRecognizer! {
        get {
            return base._fullscreenPopGestureRecognizer
        }
        //set{
        //    base._fullscreenPopGestureRecognizer = newValue
        //}
    }
    
    
    /// A view controller is able to control navigation bar's appearance by itself,
    /// rather than a global way, checking "fd_prefersNavigationBarHidden" property.
    /// Default to YES, disable it if you don't want so.
    public var viewControllerBasedNavigationBarAppearanceEnabled: Bool {
        get {
            return base._viewControllerBasedNavigationBarAppearanceEnabled
        }
        set {
            base._viewControllerBasedNavigationBarAppearanceEnabled = newValue
        }
    }
}



extension FDProxy where T: UIViewController {
    
    public var interactivePopDisabled: Bool {
        get {
            return base._interactivePopDisabled
        }
        set {
            base._interactivePopDisabled = newValue
        }
    }
    
    
    public var prefersNavigationBarHidden: Bool {
        get {
            return base._prefersNavigationBarHidden
        }
        set {
            base._prefersNavigationBarHidden = newValue
        }
    }
    
    
    public var interactivePopMaxAllowedInitialDistanceToLeftEdge: CGFloat {
        get {
            return base._interactivePopMaxAllowedInitialDistanceToLeftEdge
        }
        set {
            base._interactivePopMaxAllowedInitialDistanceToLeftEdge = newValue
        }
    }
}



// MARK: - Private Implementation -

fileprivate class _FDFullscreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController!
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if navigationController.viewControllers.count <= 1 {
            return false
        }
        
        if let topViewController = navigationController.topViewController {
            if topViewController.fd.interactivePopDisabled {
                return false
            }
            
            let beginningLocation = gestureRecognizer.location(in: gestureRecognizer.view)
            let maxAllowed = topViewController.fd.interactivePopMaxAllowedInitialDistanceToLeftEdge
            if maxAllowed > 0 && beginningLocation.x > maxAllowed {
                return false
            }
        }
        
        if let isTransitioning = navigationController.value(forKey: "_isTransitioning") as? Bool, isTransitioning {
            return false
        }
        
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = pan.translation(in: gestureRecognizer.view)
            if translation.x <= 0 {
                return false
            }
        }
        
        
        
        return true
    }
}


private class BlockWrapper: NSObject {
    let closure: (UIViewController, Bool) -> Void
    init(closure: @escaping (UIViewController, Bool) -> Void) {
        self.closure = closure
    }
}

private var _fdViewWillAppearInjectBlockAssociationKey: UInt8 = 0
extension UIViewController {
    fileprivate typealias FDViewWillAppearInjectBlock = (UIViewController, Bool) -> Void
    fileprivate var _fdViewWillAppearInjectBlock: BlockWrapper? {
        get {
            return objc_getAssociatedObject(self, &_fdViewWillAppearInjectBlockAssociationKey) as? BlockWrapper
        }
        set {
            objc_setAssociatedObject(self, &_fdViewWillAppearInjectBlockAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

// MARK: - METHOD SWIZZLING -

/* Configuration */
private let MethodMapping1:Dictionary<String,String> = [
    "viewWillAppear:":"swizzled_viewWillAppear:"
]


private let swizzlingClass1 = UIViewController.self

extension UIViewController {
    
    override open class func initialize() {
        
        /* Filter classes */
        guard self === swizzlingClass1 else { return }
        swizzling1
    }
    
    
    func swizzled_viewWillAppear(_ animated: Bool) {
        self.swizzled_viewWillAppear(animated)
        self._fdViewWillAppearInjectBlock?.closure(self, animated)
    }
}


private let swizzling1: () = {
    for (originalSelector,swizzledSelector) in MethodMapping1 {
        let originalSelector = Selector(originalSelector)
        let swizzledSelector = Selector(swizzledSelector)
        
        let originalMethod = class_getInstanceMethod(swizzlingClass1, originalSelector)
        let swizzledMethod = class_getInstanceMethod(swizzlingClass1, swizzledSelector)
        
        let didAddMethod = class_addMethod(swizzlingClass1, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(swizzlingClass1, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}()


/* Configuration */
private let MethodMapping2:Dictionary<String,String> = [
    "pushViewController:animated:":"swizzled_pushViewController:animated:"
]


private let swizzlingClass2 = UINavigationController.self

extension UINavigationController {
    
    override open class func initialize() {
        
        /* Filter classes */
        guard self === swizzlingClass2 else { return }
        swizzling2
    }
    
    
    
    func swizzled_pushViewController(_ viewController: UIViewController, animated: Bool) {
        if interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(self.fd.fullscreenPopGestureRecognizer) == false {
            
            self.interactivePopGestureRecognizer?.view?.addGestureRecognizer(self.fd.fullscreenPopGestureRecognizer)
            
            let internalTargets = interactivePopGestureRecognizer?.value(forKey: "targets") as? [AnyObject]
            let internalTarget = internalTargets?.first?.value(forKey: "target")
            let internalAction = Selector(("handleNavigationTransition:"))
            fd.fullscreenPopGestureRecognizer.delegate = _fdPopGestureRecognizerDelegate
            fd.fullscreenPopGestureRecognizer.addTarget(internalTarget as Any, action: internalAction)
            
            self.interactivePopGestureRecognizer?.isEnabled = false
            
        }
        
        fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded(appearingViewController: viewController)
        
        if !viewControllers.contains(viewController) {
            swizzled_pushViewController(viewController, animated: animated)
        }
    }
    
    
    private func fd_setupViewControllerBasedNavigationBarAppearanceIfNeeded(appearingViewController: UIViewController) {
        if !fd.viewControllerBasedNavigationBarAppearanceEnabled {
            return
        }
        
        let block: FDViewWillAppearInjectBlock = { [weak self] (viewController: UIViewController, animated: Bool) -> Void in
            self?.setNavigationBarHidden(viewController.fd.prefersNavigationBarHidden, animated: animated)
        }
        
        appearingViewController._fdViewWillAppearInjectBlock = BlockWrapper(closure: block)
        if let disappearingViewController = viewControllers.last, disappearingViewController._fdViewWillAppearInjectBlock == nil {
            disappearingViewController._fdViewWillAppearInjectBlock = BlockWrapper(closure: block)
        }
        
    }
}


private let swizzling2: () = {
    for (originalSelector,swizzledSelector) in MethodMapping2 {
        let originalSelector = Selector(originalSelector)
        let swizzledSelector = Selector(swizzledSelector)
        
        let originalMethod = class_getInstanceMethod(swizzlingClass2, originalSelector)
        let swizzledMethod = class_getInstanceMethod(swizzlingClass2, swizzledSelector)
        
        let didAddMethod = class_addMethod(swizzlingClass2, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(swizzlingClass2, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}()


private var _fdPopGestureRecognizerDelegateAssociationKey: UInt8 = 0
extension UINavigationController {
    fileprivate var _fdPopGestureRecognizerDelegate: _FDFullscreenPopGestureRecognizerDelegate {
        if let delegate = objc_getAssociatedObject(self, &_fdPopGestureRecognizerDelegateAssociationKey) as? _FDFullscreenPopGestureRecognizerDelegate {
            return delegate
        }
        
        let delegate = _FDFullscreenPopGestureRecognizerDelegate()
        delegate.navigationController = self
        objc_setAssociatedObject(self, &_fdPopGestureRecognizerDelegateAssociationKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return delegate
    }
}
