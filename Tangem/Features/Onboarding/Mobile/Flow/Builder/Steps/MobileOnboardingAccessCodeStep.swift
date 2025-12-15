//
//  MobileOnboardingAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk

final class MobileOnboardingAccessCodeStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingAccessCodeViewModel

    init(
        mode: MobileOnboardingAccessCodeViewModel.Mode,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingAccessCodeDelegate
    ) {
        viewModel = MobileOnboardingAccessCodeViewModel(
            mode: mode,
            source: source,
            delegate: delegate
        )
    }

    override func build() -> any View {
        MobileOnboardingAccessCodeView(viewModel: viewModel)
    }
}
