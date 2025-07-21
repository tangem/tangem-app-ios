//
//  HotOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingSeedPhraseRecoveryStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseRecoveryViewModel

    init(delegate: HotOnboardingSeedPhraseRecoveryDelegate) {
        viewModel = HotOnboardingSeedPhraseRecoveryViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}
