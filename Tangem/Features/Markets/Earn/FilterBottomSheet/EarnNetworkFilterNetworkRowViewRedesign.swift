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
    private let input: EarnNetworkFilterNetworkRowInput

    @ScaledMetric private var verticalPadding: CGFloat
    @ScaledMetric private var horizontalSpacing: CGFloat
    @ScaledMetric private var textSpacing: CGFloat
    @ScaledSize private var networkIconSize: CGSize
    @ScaledSize private var markIconSize: CGSize

    private var isSelected: Bool {
        input.isSelected
    }

    init(input: EarnNetworkFilterNetworkRowInput) {
        self.input = input

        _verticalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _horizontalSpacing = ScaledMetric(wrappedValue: .unit(.x2))
        _textSpacing = ScaledMetric(wrappedValue: .unit(.x1))
        _networkIconSize = ScaledSize(wrappedValue: CGSize(bothDimensions: .unit(.x10)))
        _markIconSize = ScaledSize(wrappedValue: CGSize(bothDimensions: .unit(.x5)))
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
                size: networkIconSize
            )

            HStack(alignment: .lastTextBaseline, spacing: textSpacing) {
                Text(input.networkName)
                    .style(.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)

                Text(input.currencySymbol)
                    .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.secondary)
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
        .frame(size: markIconSize)
    }
}
