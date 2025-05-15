//
//  UIWindow+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

public extension UIWindow {
    var topViewController: UIViewController? {
        return rootViewController?.topViewController
    }
}
