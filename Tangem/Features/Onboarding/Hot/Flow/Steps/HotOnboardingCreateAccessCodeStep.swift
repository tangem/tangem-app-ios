//
//  HotOnboardingCreateAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingCreateAccessCodeStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingAccessCodeCreateViewModel

    init(
        coordinator: HotOnboardingAccessCodeCreateRoutable,
        delegate: HotOnboardingAccessCodeCreateDelegate
    ) {
        viewModel = HotOnboardingAccessCodeCreateViewModel(coordinator: coordinator, delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingAccessCodeCreateView(viewModel: viewModel)
    }
}
