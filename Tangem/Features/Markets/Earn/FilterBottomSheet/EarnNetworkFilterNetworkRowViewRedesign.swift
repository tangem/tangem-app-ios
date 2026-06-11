//
//  EarnNetworkFilterNetworkRowViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct EarnNetworkFilterNetworkRowViewRedesign: View {
    let input: EarnNetworkFilterNetworkRowInput

    @ScaledMetric private var verticalPadding = CGFloat.unit(.x3)
    @ScaledMetric private var horizontalSpacing = CGFloat.unit(.x3)
    @ScaledMetric private var textSpacing = CGFloat.unit(.x1)
    @ScaledMetric private var networkIconSide = CGFloat.unit(.x10)
    @ScaledMetric private var markIconSide = CGFloat.unit(.x5)

    private var isSelected: Bool {
        input.isSelected
    }

    var body: some View {
        Button(action: input.onTap) {
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
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                Text(input.currencySymbol)
                    .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
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
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primaryInvertedConstant)
                    .background(Color.Tangem.Graphic.Status.accent, in: .circle)
            }
        }
        .frame(width: markIconSide, height: markIconSide)
    }
}
