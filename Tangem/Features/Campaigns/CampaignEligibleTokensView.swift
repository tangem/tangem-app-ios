//
//  CampaignEligibleTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct CampaignEligibleTokensView: View {
    let rows: [CampaignTokenSelectorViewModel.EligibleTokenRowViewData]
    let onAdd: (TokenItem) -> Void

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.promoCampaignEligibleTokens)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        CampaignEligibleTokenRowView(viewData: row) {
                            onAdd(row.tokenItem)
                        }
                    }
                }
                .background(Colors.Background.action)
                .cornerRadiusContinuous(14)
            }
        }
    }
}

// MARK: - Row

private struct CampaignEligibleTokenRowView: View {
    let viewData: CampaignTokenSelectorViewModel.EligibleTokenRowViewData
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
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)

                    Text(viewData.symbol)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                }

                Text(viewData.networkName)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            TangemButtonV2(
                label: AttributedString(Localization.marketsAddToken),
                accessibilityLabel: Localization.marketsAddToken,
                action: addAction
            )
            .styleType(.secondary)
            .size(.x9)
            .horizontalLayout(.intrinsic)
        }
        .padding(.all, 16)
    }
}
