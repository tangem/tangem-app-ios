//
//  HotOnboardingImportWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingImportWalletView: View {
    let viewModel: HotOnboardingImportWalletViewModel

    var body: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel.seedPhraseViewModel)
    }
}
