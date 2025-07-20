//
//  HotOnboardingValidateAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingValidateAccessCodeStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotAccessCodeViewModel

    init(manager: CommonHotAccessCodeManager) {
        viewModel = HotAccessCodeViewModel(manager: manager)
    }

    func build() -> some View {
        HotAccessCodeView(viewModel: viewModel)
    }
}
