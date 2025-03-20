//
//  UIViewController+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    @objc var topViewController: UIViewController? { return presentedViewController?.topViewController ?? self }
}

extension UITabBarController {
    override var topViewController: UIViewController? {
        return selectedViewController?.topViewController
    }
}

extension UIWindow {
    var topViewController: UIViewController? {
        return rootViewController?.topViewController
    }
}
