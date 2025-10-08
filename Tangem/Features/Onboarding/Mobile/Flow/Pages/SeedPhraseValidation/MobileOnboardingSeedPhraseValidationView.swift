//
//  MobileOnboardingSeedPhraseValidationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct MobileOnboardingSeedPhraseValidationView: View {
    typealias ViewModel = MobileOnboardingSeedPhraseValidationViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        switch viewModel.state {
        case .item(let item):
            state(item: item)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Subviews

private extension MobileOnboardingSeedPhraseValidationView {
    func state(item: ViewModel.StateItem) -> some View {
        OnboardingSeedPhraseUserValidationView(viewModel: OnboardingSeedPhraseUserValidationViewModel(
            mode: .mobile,
            validationInput: .init(
                secondWord: item.second,
                seventhWord: item.seventh,
                eleventhWord: item.eleventh,
                createWalletAction: viewModel.onCreateWallet
            )
        ))
    }
}
