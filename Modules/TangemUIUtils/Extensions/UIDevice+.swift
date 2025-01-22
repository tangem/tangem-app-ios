//
//  UIDevice+.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

public extension UIDevice {
    /// - Warning: Simple and naive, use with caution.
    var hasHomeScreenIndicator: Bool {
        return !UIApplication.safeAreaInsets.bottom.isZero
    }
}
