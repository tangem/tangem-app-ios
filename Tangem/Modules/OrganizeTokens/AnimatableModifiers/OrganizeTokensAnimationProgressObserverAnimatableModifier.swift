//
//  OrganizeTokensAnimationProgressObserverAnimatableModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Prevents too early removal of a draggable view from the view hierarchy at the end of drag-and-drop session.
struct OrganizeTokensAnimationProgressObserverAnimatableModifier<T>: AnimatableModifier where
    T: VectorArithmetic,
    T: Comparable {
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
