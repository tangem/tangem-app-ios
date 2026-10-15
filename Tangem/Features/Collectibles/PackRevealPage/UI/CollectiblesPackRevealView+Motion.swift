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
        static let cardCornerRadiusOfWidth: CGFloat = 0.043
        static let cardCenterOfScreenHeight: CGFloat = 0.403
        static let perspectiveOfScreenWidth: CGFloat = 1.923

        static let cardStartScale: CGFloat = 0.5
        static let cardPeakScale: CGFloat = 1.2
        static let cardStartLift: CGFloat = 0.221
        static let cardPeakLift: CGFloat = -0.053

        static let frameStartScale: CGFloat = 0.8
        static let tapSpin: Animation = .easeInOut(duration: 0.8)

        static let chromeRiseOffset: CGFloat = 30
        static let chromeRise: Animation = .timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.45)
        static let chromeFade: Animation = .timingCurve(0.33, 1, 0.68, 1, duration: 0.25)

        static func appear(_ timing: Timing) -> Animation {
            .timingCurve(0.30, 0.26, 0.14, 1.00, duration: timing.appear)
        }

        static func rise(_ timing: Timing) -> Animation {
            .timingCurve(0.25, 0, 0.20, 1, duration: timing.rise)
        }

        static func settle(_ timing: Timing) -> Animation {
            .timingCurve(0.80, 0, 0.20, 1, duration: timing.settle)
        }

        static func spin(_ timing: Timing) -> Animation {
            .timingCurve(0.60, 0, 0.10, 1, duration: timing.spin)
        }
    }
}

// MARK: - Timing

extension CollectiblesPackRevealView.Motion {
    struct Timing {
        let appear, rise, settle, spin, landing: Double

        static let regular = Timing(appear: 2, rise: 2, settle: 1.5, spin: 2.75, landing: 0.8)
        static let skipped = Timing(appear: 1.14, rise: 1.14, settle: 0.86, spin: 1.57, landing: 0.46)
    }
}
