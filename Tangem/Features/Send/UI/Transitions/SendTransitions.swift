//
//  SendTransitions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendTransitions {
    // MARK: - Transition

    static let transition: AnyTransition = newTransition(direction: .bottomToTop)
    static let animationDuration: TimeInterval = 0.6
    static let animation: Animation = .timingCurve(0.65, 0, 0.35, 1, duration: animationDuration)
}

// MARK: - New transition

private extension SendTransitions {
    static func newTransition(direction: Direction) -> AnyTransition {
        let direction: (insertion: CGFloat, removal: CGFloat) = switch direction {
        case .topToBottom: (70, -70)
        case .bottomToTop: (-70, 70)
        }

        let animation: (insertion: Animation, removal: Animation) = (
            insertion: animation.speed(2).delay(animationDuration / 2),
            removal: animation.speed(2)
        )

        let insertion: AnyTransition = .offset(y: direction.insertion)
        let removal: AnyTransition = .offset(y: direction.removal).animation(animation.removal)
        let opacity: AnyTransition = .opacity

        return .asymmetric(
            insertion: insertion.combined(with: opacity).animation(animation.insertion),
            removal: removal.combined(with: opacity).animation(animation.removal)
        )
    }
}

extension SendTransitions {
    enum Direction {
        case topToBottom
        case bottomToTop
    }
}
