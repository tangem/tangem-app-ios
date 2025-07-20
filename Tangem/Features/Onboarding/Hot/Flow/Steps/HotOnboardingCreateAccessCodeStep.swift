//
//  HotOnboardingCreateAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingCreateAccessCodeStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotOnboardingAccessCodeCreateViewModel

    init(
        coordinator: HotOnboardingAccessCodeCreateRoutable,
        delegate: HotOnboardingAccessCodeCreateDelegate
    ) {
        viewModel = HotOnboardingAccessCodeCreateViewModel(coordinator: coordinator, delegate: delegate)
    }

    func build() -> some View {
        HotOnboardingAccessCodeCreateView(viewModel: viewModel)
    }
}
