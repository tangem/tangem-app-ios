//
//  EarnNetworkFilterNetworkRowViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct EarnNetworkFilterNetworkRowViewRedesign: View {
    let input: EarnNetworkFilterNetworkRowInput

    @ScaledMetric private var verticalPadding: CGFloat = 12
    @ScaledMetric private var horizontalSpacing: CGFloat = 12
    @ScaledMetric private var textSpacing: CGFloat = 4
    @ScaledMetric private var networkIconSide: CGFloat = 40
    @ScaledMetric private var markIconSide: CGFloat = 20

    private var isSelected: Bool {
        input.isSelected
    }

    var body: some View {
        SwiftUI.Button(action: input.onTap) {
            label
                .padding(.vertical, verticalPadding)
        }
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterNetworkRowViewRedesign {
    var label: some View {
        HStack(spacing: horizontalSpacing) {
            NetworkIcon(
                imageAsset: input.iconAsset,
                isActive: false,
                isMainIndicatorVisible: false,
                size: CGSize(width: networkIconSide, height: networkIconSide)
            )

            HStack(alignment: .lastTextBaseline, spacing: textSpacing) {
                Text(input.networkName)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(input.currencySymbol)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .lineLimit(1)

            Spacer()

            icon
        }
    }

    var icon: some View {
        Group {
            if isSelected {
                Assets.checkmark20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .background(DesignSystem.Color.iconAccentBlue, in: .circle)
            }
        }
        .frame(width: markIconSide, height: markIconSide)
    }
}
