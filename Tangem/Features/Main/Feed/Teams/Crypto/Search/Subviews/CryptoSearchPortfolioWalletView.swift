//
//  CryptoSearchPortfolioWalletView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CryptoSearchPortfolioWalletView: View {
    let wallet: MarketsPortfolioTokenListViewModel.WalletSection

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.accountSpacing) {
            header

            ForEach(wallet.accounts, id: \.id) { account in
                CryptoSearchPortfolioAccountView(walletID: wallet.id, account: account)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Constants.titleSpacing) {
            Text(wallet.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            wallet.thumbnail.map {
                MiniatureWalletView(type: $0)
                    .frame(width: Constants.thumbnailSide, height: Constants.thumbnailSide)
            }
        }
        .padding(.vertical, Constants.verticalPadding)
    }
}

// MARK: - Constants

private extension CryptoSearchPortfolioWalletView {
    enum Constants {
        static let accountSpacing: CGFloat = 8
        static let titleSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let thumbnailSide: CGFloat = 20
    }
}
