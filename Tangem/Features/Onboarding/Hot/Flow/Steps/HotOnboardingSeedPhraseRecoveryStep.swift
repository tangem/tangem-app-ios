//
//  HotOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

final class HotOnboardingSeedPhraseRecoveryStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseRecoveryViewModel

    init(userWalletId: UserWalletId, delegate: HotOnboardingSeedPhraseRecoveryDelegate) {
        viewModel = HotOnboardingSeedPhraseRecoveryViewModel(userWalletId: userWalletId, delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}
