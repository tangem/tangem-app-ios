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

    init(mode: HotOnboardingAccessCodeViewModel.Mode, delegate: HotOnboardingAccessCodeDelegate) {
        viewModel = HotOnboardingAccessCodeViewModel(mode: mode, delegate: delegate)
    }

    convenience init(context: MobileWalletContext, delegate: HotOnboardingAccessCodeDelegate) {
        self.init(mode: .change(context), delegate: delegate)
    }

    convenience init(delegate: HotOnboardingAccessCodeDelegate) {
        self.init(mode: .create, delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingAccessCodeView(viewModel: viewModel)
    }
}
