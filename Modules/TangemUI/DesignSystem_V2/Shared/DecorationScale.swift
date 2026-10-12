//
//  DecorationScale.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

enum DecorationScale {
    private static let minMultiplier: CGFloat = 1
    private static let maxMultiplier: CGFloat = 1.5

    static func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minMultiplier), maxMultiplier)
    }
}
