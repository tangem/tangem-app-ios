//
//  MobileOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseRecoveryStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseRecoveryViewModel

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        context: MobileWalletContext,
        delegate: MobileOnboardingSeedPhraseRecoveryDelegate
    ) {
        viewModel = MobileOnboardingSeedPhraseRecoveryViewModel(
            userWalletModel: userWalletModel,
            source: source,
            context: context,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        MobileOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}
