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

    init(delegate: HotOnboardingAccessCodeCreateDelegate) {
        viewModel = HotOnboardingAccessCodeCreateViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingAccessCodeCreateView(viewModel: viewModel)
    }
}
