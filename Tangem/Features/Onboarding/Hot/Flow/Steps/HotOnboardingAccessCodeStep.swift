//
//  HotOnboardingAccessCodeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemHotSdk

final class HotOnboardingAccessCodeStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingAccessCodeViewModel

    init(context: MobileWalletContext?, delegate: HotOnboardingAccessCodeDelegate) {
        let mode: HotOnboardingAccessCodeViewModel.Mode = if let context {
            .change(context)
        } else {
            .create
        }
        viewModel = HotOnboardingAccessCodeViewModel(mode: mode, delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingAccessCodeView(viewModel: viewModel)
    }
}
