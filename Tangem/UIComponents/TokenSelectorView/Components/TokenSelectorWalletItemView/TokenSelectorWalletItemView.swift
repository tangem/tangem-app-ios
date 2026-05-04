//
//  TokenSelectorWalletItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TokenSelectorWalletItemView: View {
    @ObservedObject var viewModel: TokenSelectorWalletItemViewModel

    var body: some View {
        switch viewModel.viewType {
        case .wallet(let accountViewModel) where viewModel.contentVisibility?.isVisible == true:
            TokenSelectorAccountView(viewModel: accountViewModel)

        case .accounts(let walletName, let accounts) where viewModel.contentVisibility?.isVisible == true:
            VStack(spacing: Constants.accountsListVerticalSpacing) {
                header(walletName: walletName)
                    .background(Colors.Background.tertiary)
                    .zIndex(100.0) // Keeps the header above the expanding accounts list and other content within the stack

                if viewModel.isOpen {
                    ForEach(indexed: accounts.indexed()) { _, viewModel in
                        TokenSelectorAccountView(viewModel: viewModel)
                    }
                    .zIndex(50.0) // To place it above the separator so that it won't overlap the separator when the list is expanded
                    .transition(.move(edge: .top))
                } else {
                    Separator(color: Colors.Stroke.primary)
                        .transition(.opacity)
                }
            }
            .clipped() // Clips the content (`TokenSelectorAccountView`) when the list is expanded

        case .wallet, .accounts:
            EmptyView()
        }
    }

    private func header(walletName: String) -> some View {
        Button(action: { viewModel.toggleIsOpen() }) {
            HStack(spacing: .zero) {
                Text(walletName)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                Spacer(minLength: Constants.headerHorizontalSpacing)

                isOpenButton
            }
            .padding(.horizontal, Constants.headerHorizontalSpacing)
            .padding(.vertical, 2)
        }
    }

    private var isOpenButton: some View {
        CircleButton.back(action: {})
            .allowsHitTesting(false)
            .rotationEffect(.degrees(180))
            .rotationEffect(.degrees(viewModel.isOpen ? 90 : -90))
            .animation(.spring(duration: 0.2), value: viewModel.isOpen)
    }
}

// MARK: - Constants

private extension TokenSelectorWalletItemView {
    enum Constants {
        static let accountsListVerticalSpacing = 8.0
        static let headerHorizontalSpacing = 8.0
    }
}
