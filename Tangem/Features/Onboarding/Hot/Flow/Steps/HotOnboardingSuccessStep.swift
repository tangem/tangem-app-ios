//
//  HotOnboardingSuccessStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingSuccessStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSuccessViewModel

    init(
        type: HotOnboardingSuccessViewModel.SuccessType,
        onAppear: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        viewModel = HotOnboardingSuccessViewModel(
            type: type,
            onAppear: onAppear,
            onComplete: onComplete
        )
    }

    override func build() -> any View {
        HotOnboardingSuccessView(viewModel: viewModel)
    }
}
