//
//  OrganizeTokensAnimationProgressObserverModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Prevents too early removal of a draggable view from the view hierarchy at the end of drag-and-drop session.
struct OrganizeTokensAnimationProgressObserverModifier<T>: AnimatableModifier where T: VectorArithmetic, T: Comparable {
    var animatableData: T {
        didSet {
            if animatableData <= progressThreshold, !didTriggerAction {
                didTriggerAction = true
                action()
            }
        }
    }

    private let progressThreshold: T
    private let action: () -> Void

    @State private var didTriggerAction = false

    init(
        targetProgress: T,
        progressThreshold: T,
        _ action: @escaping () -> Void
    ) {
        animatableData = targetProgress
        self.progressThreshold = progressThreshold
        self.action = action
    }

    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Convenience extensions

extension OrganizeTokensAnimationProgressObserverModifier where T: ExpressibleByFloatLiteral {
    /// Useful for creating asymetric transitions using `AnyTransition.asymmetric(insertion:removal:)`,
    /// when you don't want to observe both insertion and removal.
    static var dummy: Self { Self(targetProgress: 0.0, progressThreshold: 0.0) {} }
}
