//
//  HotOnboardingFlowStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

protocol HotOnboardingFlowStep:
    HotOnboardingFlowStepTransformable,
    HotOnboardingFlowStepNavigationConfigurable,
    HotOnboardingFlowStepProgressSetupable {
    associatedtype Content: View

    @ViewBuilder
    func build() -> Content

    @ViewBuilder
    func buildWithTransformations() -> any View
}

extension HotOnboardingFlowStep {
    @ViewBuilder
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
