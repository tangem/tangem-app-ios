//
//  CollectiblesPackRevealView+Motion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension CollectiblesPackRevealView {
    enum Motion {
        static let videoFlashTime: Double = 7
        static let videoEndTolerance: Double = 0.1
        static let videoPollInterval: Duration = .milliseconds(30)
        static let videoStallTimeout: Duration = .seconds(3)

        static let cardWidthOfScreen: CGFloat = 0.577
        static let cardAspect: CGFloat = 0.757
        static let cardCornerRadiusOfWidth: CGFloat = 0.043
        static let cardCenterOfScreenHeight: CGFloat = 0.403
        static let perspectiveOfScreenWidth: CGFloat = 1.923

        static let cardStartScale: CGFloat = 0.5
        static let cardPeakScale: CGFloat = 1.2
        static let cardStartLift: CGFloat = 0.221
        static let cardPeakLift: CGFloat = -0.053

        static let riseDuration: Duration = .milliseconds(2000)
        static let landingTime: Duration = .milliseconds(800)

        static let whiteOverlayFade: Animation = .timingCurve(0.30, 0.26, 0.14, 1.00, duration: 2)
        static let rise: Animation = .timingCurve(0.25, 0, 0.20, 1, duration: 2)
        static let settle: Animation = .timingCurve(0.80, 0, 0.20, 1, duration: 1.5)
        static let spin: Animation = .timingCurve(0.60, 0, 0.10, 1, duration: 2.75)
        static let tapSpin: Animation = .easeInOut(duration: 0.8)

        static let detailsOffset: CGFloat = 120
        static let detailsAppearance: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.32)
    }
}
