//
//  UIViewController.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

import UIKit

extension UIViewController {
    @objc var topmostViewController: UIViewController? { return presentedViewController?.topmostViewController ?? self }
}

extension UINavigationController {
    override var topmostViewController: UIViewController? {
        return visibleViewController?.topmostViewController
    }
}

extension UITabBarController {
    override var topmostViewController: UIViewController? {
        return selectedViewController?.topmostViewController
    }
}

extension UIWindow {
    var topmostViewController: UIViewController? {
        return rootViewController?.topmostViewController
    }
}

extension UIApplication {
    var topMostViewController : UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return keyWindow?.topmostViewController
    }
}
