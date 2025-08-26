//
//  MobileOnboardingCreateWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingCreateWalletStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingCreateWalletViewModel

    init(delegate: MobileOnboardingCreateWalletDelegate) {
        viewModel = MobileOnboardingCreateWalletViewModel(delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingCreateWalletView(viewModel: viewModel)
    }
}
