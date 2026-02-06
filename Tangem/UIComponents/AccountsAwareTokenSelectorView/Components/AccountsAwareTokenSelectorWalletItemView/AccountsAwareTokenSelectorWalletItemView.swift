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
        case .wallet(let accountViewModel) where viewModel.contentVisibility == .visible:
            AccountsAwareTokenSelectorAccountView(viewModel: accountViewModel)

        case .accounts(let walletName, let accounts) where viewModel.contentVisibility == .visible:
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

                isOpenButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }

    private var isOpenButton: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: {}) {
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Colors.Text.primary1)
                        .font(.title2)
                        .fontWeight(.medium)
                        .frame(width: 20, height: 20)
                        .padding(12)
                }
                // [REDACTED_USERNAME], important to place transform effect before glass effect.
                // Animation will cause scaling glitch otherwise.
                .rotationEffect(.degrees(viewModel.isOpen ? 0 : 180))
                .glassEffect(.regular, in: .circle)
            } else {
                NavigationBarButton.back(action: {})
                    .rotationEffect(.degrees(viewModel.isOpen ? -90 : 90))
            }
        }
        .allowsHitTesting(false)
        .animation(.spring(duration: 0.2), value: viewModel.isOpen)
    }
}
