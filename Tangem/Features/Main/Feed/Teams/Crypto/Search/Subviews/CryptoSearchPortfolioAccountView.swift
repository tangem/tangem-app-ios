//
//  CryptoSearchPortfolioAccountView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts
import TangemUI

struct CryptoSearchPortfolioAccountView: View {
    let account: MarketsPortfolioTokenListViewModel.AccountSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ForEach(Array(account.tokenRows.enumerated()), id: \.offset) { _, row in
                CryptoSearchPortfolioTokenRow(viewModel: row.model, onTap: row.onTap)
            }
        }
        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }

    private var header: some View {
        AccountIconWithContentView(
            iconData: AccountModelUtils.UI.iconViewData(icon: account.icon, accountName: account.title),
            name: account.title
        )
        .iconSettings(.smallSized)
        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.horizontalPadding)
        .padding(.bottom, Constants.headerBottomPadding)
    }
}

// MARK: - Constants

private extension CryptoSearchPortfolioAccountView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 24
    }
}
