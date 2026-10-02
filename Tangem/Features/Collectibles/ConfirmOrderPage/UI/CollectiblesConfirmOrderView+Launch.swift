//
//  CollectiblesConfirmOrderView+Launch.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension CollectiblesConfirmOrderView {
    enum PackPose: Equatable {
        case resting
        case dipped
        case launched

        var offset: CGSize {
            switch self {
            case .resting: .zero
            case .dipped: CGSize(width: -16, height: 12)
            case .launched: CGSize(width: 44, height: -72)
            }
        }

        var scale: CGFloat {
            switch self {
            case .resting: 1
            case .dipped: 0.94
            case .launched: 1.06
            }
        }

        var rotation: Angle {
            switch self {
            case .resting, .dipped: .zero
            case .launched: .degrees(7)
            }
        }

        var animation: Animation? {
            switch self {
            case .resting: nil
            case .dipped: Launch.dip
            case .launched: Launch.launch
            }
        }
    }

    enum Launch {
        static let dipDuration: Duration = .milliseconds(260)
        static let exitOffset: CGFloat = 120

        static let dip: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.26)
        static let launch: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.46)
        static let packFade: Animation = .linear(duration: 0.276).delay(0.184)
        static let buttonExit: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.32)
        static let rowsExit: Animation = buttonExit.delay(0.09)
    }
}
