//
//  TangemPayWalletSelectorProxyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

/// Probably this should be replaced with AccountSelectorView
/// when account feature would be implemented
struct TangemPayWalletSelectorProxyView: View {
    var viewModel: TangemPayWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text(Localization.commonChooseWallet)
                .style(
                    Fonts.BoldStatic.body,
                    color: Colors.Text.primary1
                )

            WalletSelectorView(viewModel: viewModel.walletSelectorViewModel)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .overlay(alignment: .topTrailing) {
            NavigationBarButton
                .close(action: viewModel.onClose)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
