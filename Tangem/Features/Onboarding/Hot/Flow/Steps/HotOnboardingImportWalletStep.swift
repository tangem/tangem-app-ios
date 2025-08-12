//
//  HotOnboardingImportWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingImportWalletStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseImportViewModel

    init(delegate: HotOnboardingSeedPhraseImportDelegate) {
        viewModel = HotOnboardingSeedPhraseImportViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
