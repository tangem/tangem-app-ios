//
//  MobileOnboardingImportWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingImportWalletStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseImportViewModel

    init(delegate: MobileOnboardingSeedPhraseImportDelegate) {
        viewModel = MobileOnboardingSeedPhraseImportViewModel(delegate: delegate)
    }

    override func makeView() -> any View {
        MobileOnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
