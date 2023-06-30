//
//  OrganizeTokensAnimationProgressObserverModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Temporary workaround for too early removal of a draggable view from the view hierarchy at the end of drag-and-drop session.
///
/// Should be removed in [REDACTED_INFO] after migration from SwiftUI transitions to plain SwiftUI animations.
struct OrganizeTokensAnimationProgressObserverModifier<T>: AnimatableModifier where T: VectorArithmetic, T: Comparable {
    let threshold: T
    let action: () -> Void

    var animatableData: T {
        didSet {
            if animatableData <= threshold, !didTriggerAction {
                didTriggerAction = true
                action()
            }
        }
    }

    @State private var didTriggerAction = false

    init(
        progress: T,
        threshold: T,
        action: @escaping () -> Void
    ) {
        animatableData = progress
        self.threshold = threshold
        self.action = action
    }

    func body(content: Content) -> some View {
        content
    }
}
