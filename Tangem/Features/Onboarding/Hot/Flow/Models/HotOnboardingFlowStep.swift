//
//  HotOnboardingFlowStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

class HotOnboardingFlowStep:
    HotOnboardingFlowStepTransformable,
    HotOnboardingFlowStepNavBarConfigurable,
    HotOnboardingFlowStepProgressBarConfigurable {
    var transformations: [TransformationModifier<AnyView>] = []

    func build() -> any View {
        EmptyView()
    }

    func buildWithTransformations() -> any View {
        transformations.reduce(AnyView(build())) { view, transformation in
            AnyView(view.modifier(transformation))
        }
    }
}

// MARK: - TransformationModifier

struct TransformationModifier<T: View>: ViewModifier {
    @ViewBuilder let transformation: (Content) -> T

    func body(content: Content) -> T {
        transformation(content)
    }
}
