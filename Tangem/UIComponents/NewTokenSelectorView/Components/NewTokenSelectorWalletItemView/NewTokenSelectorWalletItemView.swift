//
//  NewTokenSelectorWalletItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct NewTokenSelectorWalletItemView: View {
    @ObservedObject var viewModel: NewTokenSelectorWalletItemViewModel
    let shouldShowSeparator: Bool

    var body: some View {
        switch viewModel.viewType {
        case .none:
            EmptyView()
        case .wallet(let viewModel):
            NewTokenSelectorAccountView(viewModel: viewModel)
        case .accounts(let walletName, let accounts):
            header(walletName: walletName)

            if viewModel.isOpen {
                ForEach(accounts) {
                    NewTokenSelectorAccountView(viewModel: $0)
                }
            } else if shouldShowSeparator {
                Separator(color: Colors.Stroke.primary)
            }
        }
    }

    private func header(walletName: String) -> some View {
        Button(action: { viewModel.isOpen.toggle() }) {
            HStack(spacing: .zero) {
                Text(walletName)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                Spacer(minLength: 8)

                CircleButton.back(action: {})
                    .allowsHitTesting(false)
                    .rotationEffect(.degrees(180))
                    .rotationEffect(.degrees(viewModel.isOpen ? 90 : -90))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }
}
