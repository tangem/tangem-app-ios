//
//  TokenSelectorWalletItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TokenSelectorWalletItemView: View {
    @ObservedObject var viewModel: TokenSelectorWalletItemViewModel

    var body: some View {
        content
            .collapsedIfHidden(viewModel.isFilteredOut)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewType {
        case .wallet(let accountViewModel) where viewModel.contentVisibility?.isVisible == true:
            TokenSelectorAccountView(viewModel: accountViewModel)

        case .accounts(let accounts) where viewModel.contentVisibility?.isVisible == true:
            VStack(spacing: Constants.accountsListVerticalSpacing) {
                ForEach(indexed: accounts.indexed()) { _, viewModel in
                    TokenSelectorAccountView(viewModel: viewModel)
                }
            }

        case .wallet, .accounts:
            EmptyView()
        }
    }
}

// MARK: - Constants

private extension TokenSelectorWalletItemView {
    enum Constants {
        static let accountsListVerticalSpacing = 8.0
    }
}
