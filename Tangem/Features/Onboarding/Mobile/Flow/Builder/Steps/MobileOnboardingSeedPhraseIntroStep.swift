//
//  MobileOnboardingSeedPhraseIntroStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingSeedPhraseIntroStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseIntroViewModel

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingSeedPhraseIntroDelegate
    ) {
        viewModel = MobileOnboardingSeedPhraseIntroViewModel(
            userWalletModel: userWalletModel,
            source: source,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        MobileOnboardingSeedPhraseIntroView(viewModel: viewModel)
    }
}
