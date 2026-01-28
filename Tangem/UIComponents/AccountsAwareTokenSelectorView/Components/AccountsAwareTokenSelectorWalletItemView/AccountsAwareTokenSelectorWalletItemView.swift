//
//  AccountsAwareTokenSelectorWalletItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AccountsAwareTokenSelectorWalletItemView: View {
    @ObservedObject var viewModel: AccountsAwareTokenSelectorWalletItemViewModel

    var body: some View {
        switch viewModel.viewType {
        case .wallet(let accountViewModel) where viewModel.contentVisibility?.isVisible == true:
            AccountsAwareTokenSelectorAccountView(viewModel: accountViewModel)

        case .accounts(let walletName, let accounts) where viewModel.contentVisibility?.isVisible == true:
            LazyVStack(spacing: 8) {
                header(walletName: walletName)

                if viewModel.isOpen {
                    ForEach(accounts) { AccountsAwareTokenSelectorAccountView(viewModel: $0) }
                } else {
                    Separator(color: Colors.Stroke.primary)
                }
            }

        case .wallet, .accounts:
            EmptyView()
        }
    }

    private func header(walletName: String) -> some View {
        Button(action: { viewModel.toggleIsOpen() }) {
            HStack(spacing: .zero) {
                Text(walletName)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                Spacer(minLength: 8)

                NavigationBarButton.back(action: {})
                    .allowsHitTesting(false)
                    .rotationEffect(.degrees(180))
                    .rotationEffect(.degrees(viewModel.isOpen ? 90 : -90))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }
}
