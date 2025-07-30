//
//  HotOnboardingCreateWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingCreateWalletStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingCreateWalletViewModel

    init(delegate: HotOnboardingCreateWalletDelegate) {
        viewModel = HotOnboardingCreateWalletViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingCreateWalletView(viewModel: viewModel)
    }
}
