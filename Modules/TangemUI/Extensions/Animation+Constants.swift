//
//  Animation+Constants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension Animation {
    /// Mimics iOS default keyboard animation.
    /// - Note: almost identical.
    static let keyboard = Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500)

    /// Cubic bezier animation. Like `easyOut` but a bit different
    /// https://cubic-bezier.com/#.25,.1,.25,1
    static func cubicBezier(duration: TimeInterval = 0.2) -> Animation {
        .timingCurve(0.17, 0.67, 0.83, 0.67, duration: duration)
    }
}
