//
//  HotOnboardingSuccessStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSuccessStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

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

    func build() -> some View {
        HotOnboardingSuccessView(viewModel: viewModel)
    }
}
