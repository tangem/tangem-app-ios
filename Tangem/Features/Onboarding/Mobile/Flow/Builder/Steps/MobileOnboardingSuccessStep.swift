//
//  MobileOnboardingSuccessStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingSuccessStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSuccessViewModel

    init(
        type: MobileOnboardingSuccessViewModel.SuccessType,
        navigationTitle: String,
        onAppear: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        viewModel = MobileOnboardingSuccessViewModel(
            type: type,
            navigationTitle: navigationTitle,
            onAppear: onAppear,
            onComplete: onComplete
        )
    }

    override func makeView() -> any View {
        MobileOnboardingSuccessView(viewModel: viewModel)
    }
}
