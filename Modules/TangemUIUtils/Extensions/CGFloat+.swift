//
//  CGFloat+.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

public extension CGFloat {
    /// Snaps the value to the device pixel grid.
    ///
    /// Use when a measured geometry value is written into state that feeds back into the layout
    /// of the measured subtree: raw measurements carry floating-point noise, never compare equal,
    /// and keep the layout invalidation loop spinning forever ([REDACTED_INFO]).
    func roundedToDeviceScale() -> CGFloat {
        let scale = UIScreen.main.scale
        return (self * scale).rounded() / scale
    }
}
