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
            case .dipped: CGSize(width: -5, height: 17)
            case .launched: CGSize(width: 45, height: -45)
            }
        }

        var scale: CGFloat {
            switch self {
            case .resting: 1
            case .dipped: 1.01
            case .launched: 0.84
            }
        }

        var rotationX: Angle {
            switch self {
            case .resting: .zero
            case .dipped: .degrees(-4)
            case .launched: .degrees(35)
            }
        }

        var rotationY: Angle {
            switch self {
            case .resting, .dipped: .zero
            case .launched: .degrees(16)
            }
        }

        var rotationZ: Angle {
            switch self {
            case .resting, .dipped: .zero
            case .launched: .degrees(3)
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
        static let dipDuration: Duration = .milliseconds(100)
        static let launchDuration: Duration = .milliseconds(400)
        static let exitOffset: CGFloat = 36
        static let packPerspective: CGFloat = (850 / 590) / 3.36

        static let dip: Animation = .timingCurve(0.33, 1, 0.68, 1, duration: 0.1)
        static let launch: Animation = .timingCurve(0.32, 0, 0.67, 0, duration: 0.4)
        static let exit: Animation = .timingCurve(0.4, 0, 1, 1, duration: 0.13).delay(0.35)
        static let buttonExitSpan: CGFloat = 0.25
        static let rowsExitDelay: CGFloat = 0.23
        static let navigationBarFade: Animation = .easeInOut(duration: 0.2)
    }
}

// MARK: - Launch exit

extension CollectiblesConfirmOrderView {
    struct LaunchExit: ViewModifier, Animatable {
        var progress: CGFloat
        let isDelayed: Bool
        let shift: CGFloat

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        func body(content: Content) -> some View {
            content
                .offset(y: shift * contentProgress)
                .opacity(1 - contentProgress)
        }

        private var contentProgress: CGFloat {
            guard isDelayed else {
                return min(max(progress / Launch.buttonExitSpan, 0), 1)
            }

            return min(max((progress - Launch.rowsExitDelay) / (1 - Launch.rowsExitDelay), 0), 1)
        }
    }
}
