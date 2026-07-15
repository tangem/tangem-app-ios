//
//  PortfolioTokenItemView+ExpandedRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension PortfolioTokenItemView {
    /// Its own view struct: the expanded card holds a dynamic per-network list, so SwiftUI gets a
    /// distinct identity/update scope instead of re-evaluating it inline in the parent body.
    struct ExpandedRowView: View {
        let assetRow: ForYouTokenRowData
        let networkRows: [ForYouTokenRowData]
        let onToggle: () -> Void

        @ScaledMetric private var headerIconSize: CGFloat = 16

        var body: some View {
            VStack(spacing: 0) {
                header
                    .transition(.opacity)

                divider
                    .transition(.opacity)

                ForEach(networkRows) { row in
                    RowView(data: row)
                        .padding(16)
                        .transition(.opacity)
                }
            }
        }
    }
}

private extension PortfolioTokenItemView.ExpandedRowView {
    var header: some View {
        HStack(spacing: 12) {
            headerIcon

            HStack(spacing: 4) {
                Text(assetRow.symbol).style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: DesignSystem.Color.textPrimary
                )

                headerDot

                switch assetRow.end {
                case .values(let fiat, let percent):
                    Text(fiat).style(
                        DesignSystem.Font.subheadingMediumToken,
                        color: DesignSystem.Color.textPrimary
                    )

                    headerDot

                    Text(percent).style(
                        DesignSystem.Font.subheadingMediumToken,
                        color: DesignSystem.Color.textSecondary
                    )
                case .unavailable(let label):
                    Text(AppConstants.enDashSign).style(
                        DesignSystem.Font.subheadingMediumToken,
                        color: DesignSystem.Color.textPrimary
                    )

                    headerDot

                    Text(label).style(
                        DesignSystem.Font.subheadingMediumToken,
                        color: DesignSystem.Color.textStatusWarning
                    )
                }
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            DesignSystem.Icons.ChevronCollapse.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }

    @ViewBuilder
    var headerIcon: some View {
        if let tokenIconInfo = assetRow.tokenIconInfo {
            TokenIcon(
                tokenIconInfo: tokenIconInfo,
                size: CGSize(width: headerIconSize, height: headerIconSize),
                isWithOverlays: false
            )
        } else {
            Circle()
                .fill(DesignSystem.Color.bgTertiary)
                .frame(width: headerIconSize, height: headerIconSize)
        }
    }

    var headerDot: some View {
        Circle()
            .fill(DesignSystem.Color.iconTertiary)
            .frame(width: 3, height: 3)
    }

    var divider: some View {
        Rectangle()
            .fill(DesignSystem.Color.borderSecondary)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}
