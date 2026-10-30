//
//  SwapOfferedTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SwapOfferedTokensView: View {
    let rows: [SwapOfferedTokensViewModel.RowViewData]
    let showsEmptyMessage: Bool
    let onAdd: (TokenItem) -> Void

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if showsEmptyMessage {
                    SwapOfferedTokensEmptyView()
                        .padding(.bottom, 16)
                }

                Text(Localization.marketsPortfolioEligibleBlockTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        SwapOfferedTokenRowView(viewData: row) {
                            onAdd(row.tokenItem)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Empty content

private struct SwapOfferedTokensEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            icon

            Text(Localization.swapTokenSelectorEmptyFilteredMessage)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(SwapMarketsTokensView.Constants.cornerRadius)
    }

    private var icon: some View {
        Assets.infoCircle20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgTransparentSecondary, in: Circle())
    }
}

// MARK: - Row

private struct SwapOfferedTokenRowView: View {
    let viewData: SwapOfferedTokensViewModel.RowViewData
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(
                tokenIconInfo: viewData.iconInfo,
                size: CGSize(bothDimensions: 36)
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewData.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)

                    Text(viewData.symbol)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }

                Text(viewData.networkName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            TangemUI.Button(
                label: AttributedString(Localization.marketsAddToken),
                accessibilityLabel: Localization.marketsAddToken,
                action: addAction
            )
            .styleType(.secondary(.default))
            .size(.x9)
            .horizontalLayout(.intrinsic)
        }
        .padding(.all, 16)
    }
}
