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

    init(mode: MobileOnboardingAccessCodeViewModel.Mode, delegate: MobileOnboardingAccessCodeDelegate) {
        viewModel = MobileOnboardingAccessCodeViewModel(mode: mode, delegate: delegate)
    }

    convenience init(context: MobileWalletContext, delegate: MobileOnboardingAccessCodeDelegate) {
        self.init(mode: .change(context), delegate: delegate)
    }

    convenience init(delegate: MobileOnboardingAccessCodeDelegate) {
        self.init(mode: .create, delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingAccessCodeView(viewModel: viewModel)
    }
}
