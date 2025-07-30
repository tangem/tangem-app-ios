//
//  HotOnboardingValidateAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingValidateAccessCodeStep: HotOnboardingFlowStep {
    private let viewModel: HotAccessCodeViewModel

    init(manager: CommonHotAccessCodeManager) {
        viewModel = HotAccessCodeViewModel(manager: manager)
    }

    override func build() -> any View {
        HotAccessCodeView(viewModel: viewModel)
    }
}
