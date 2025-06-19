//
//  HotOnboardingImportWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class HotOnboardingImportWalletViewModel {
    let seedPhraseViewModel: OnboardingSeedPhraseImportViewModel

    init(delegate: HotOnboardingImportWalletDelegate) {
        seedPhraseViewModel = OnboardingSeedPhraseImportViewModel(
            inputProcessor: SeedPhraseInputProcessor(),
            delegate: delegate
        )
    }
}
