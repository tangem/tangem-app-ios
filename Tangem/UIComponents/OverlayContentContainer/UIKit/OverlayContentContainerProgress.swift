//
//  OverlayContentContainerProgress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct OverlayContentContainerProgress {
    struct AnimationContext {
        let duration: TimeInterval
        let curve: UIView.AnimationCurve
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
