//
//  OverlayContentContainerProgress.swift
//  Tangem
//
//  Created by Andrey Fedorov on 16.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

// Internal state used only by `OverlayContentContainerViewController`, do not use.
struct OverlayContentContainerProgress {
    struct AnimationContext {
        var duration: TimeInterval
        var curve: UIView.AnimationCurve
        var springDampingRatio: CGFloat
        var initialSpringVelocity: CGFloat
    }

    static var zero: Self { Self(value: .zero, context: nil) }

    let value: CGFloat

    /// An opaque value, ignored by equality check.
    let context: AnimationContext?
}

// MARK: - Equatable protocol conformance

extension OverlayContentContainerProgress: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}
