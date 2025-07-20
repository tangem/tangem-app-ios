//
//  HotOnboardingCreateWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingCreateWalletStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: HotOnboardingCreateWalletViewModel

    init(delegate: HotOnboardingCreateWalletDelegate) {
        viewModel = HotOnboardingCreateWalletViewModel(delegate: delegate)
    }

    func build() -> some View {
        HotOnboardingCreateWalletView(viewModel: viewModel)
    }
}
