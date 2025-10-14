//
//  MobileOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

final class MobileOnboardingSeedPhraseRecoveryStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseRecoveryViewModel

    init(userWalletId: UserWalletId, delegate: MobileOnboardingSeedPhraseRecoveryDelegate) {
        viewModel = MobileOnboardingSeedPhraseRecoveryViewModel(userWalletId: userWalletId, delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}
