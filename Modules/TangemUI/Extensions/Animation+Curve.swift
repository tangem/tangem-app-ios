//
//  Animation+Curve.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct AnimationCurve {
    let p1x: Double
    let p1y: Double
    let p2x: Double
    let p2y: Double

    /// **0.76**, **0**, **0.24**, **1**
    public static let easeOutEmphasized = AnimationCurve(p1x: 0.76, p1y: 0, p2x: 0.24, p2y: 1)
    /// **0.65**, **0**, **0.35**, **1**
    public static let easeOutStandard = AnimationCurve(p1x: 0.65, p1y: 0, p2x: 0.35, p2y: 1)
    /// **0.69**, **0.07**, **0.27**, **0.95**
    public static let easeInOutRefined = AnimationCurve(p1x: 0.69, p1y: 0.07, p2x: 0.27, p2y: 0.95)
}

// MARK: - Convenience extensions

public extension Animation {
    static func curve(_ curve: AnimationCurve, duration: TimeInterval) -> Animation {
        Animation.timingCurve(curve.p1x, curve.p1y, curve.p2x, curve.p2y, duration: duration)
    }
}
