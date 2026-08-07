//
//  TransactionDetailsYieldTokensView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemUI
import TangemAssets

struct TransactionDetailsYieldTokensViewData: Equatable {
    let accountIcon: AccountIconView.ViewData
    let tokenIconInfo: TokenIconInfo
    let amountText: String
    let subtitleText: String?
}

struct TransactionDetailsYieldTokensView: View {
    let data: TransactionDetailsYieldTokensViewData

    @ScaledMetric private var iconSide: CGFloat = 56
    @ScaledMetric private var overlap: CGFloat = 12

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: -overlap) {
                AccountIconView(data: data.accountIcon, settings: .largeSized)
                    .frame(size: CGSize(bothDimensions: iconSide))

                TokenIcon(tokenIconInfo: data.tokenIconInfo, size: CGSize(bothDimensions: iconSide))
            }

            VStack(spacing: 2) {
                Text(data.amountText)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let subtitleText = data.subtitleText {
                    Text(subtitleText)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Previews

#Preview("Yield tokens") {
    TransactionDetailsYieldTokensView(data: TransactionDetailsPreviewFactory.yieldTokens())
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
}
