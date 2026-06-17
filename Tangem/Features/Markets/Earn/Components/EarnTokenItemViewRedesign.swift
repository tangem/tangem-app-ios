//
//  EarnTokenItemViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct EarnTokenItemViewRedesign: View {
    let viewModel: EarnTokenItemViewModel

    @ScaledMetric private var tokenImageSide = CGFloat.unit(.x10)
    @ScaledMetric private var earnImageSide = CGFloat.unit(.x4)
    @ScaledMetric private var textHorizontalSpacing = CGFloat.unit(.x1)
    @ScaledMetric private var horizontalPadding = CGFloat.unit(.x3)
    @ScaledMetric private var verticalPadding = CGFloat.unit(.x3)

    var body: some View {
        Button(action: viewModel.onTapAction) {
            TangemTwoLineRowLayout(
                icon: icon,
                primaryLeading: primaryLeading,
                primaryTrailing: primaryTrailing,
                secondaryLeading: secondaryLeading,
                secondaryTrailing: secondaryTrailing
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subviews

private extension EarnTokenItemViewRedesign {
    func icon() -> some View {
        TokenIcon(
            tokenIconInfo: TokenIconInfo(
                name: viewModel.name,
                blockchainIconAsset: viewModel.blockchainIconAsset,
                imageURL: viewModel.imageUrl,
                isCustom: false,
                customTokenColor: nil
            ),
            size: CGSize(width: tokenImageSide, height: tokenImageSide),
            isWithOverlays: true,
            forceKingfisher: true
        )
    }

    func primaryLeading() -> some View {
        HStack(alignment: .lastTextBaseline, spacing: textHorizontalSpacing) {
            Text(viewModel.name)
                .style(Font.Tangem.Body15.semibold, color: .Tangem.Text.Neutral.primary)

            Text(viewModel.symbol)
                .style(Font.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.secondary)
        }
        .lineLimit(1)
    }

    func primaryTrailing() -> some View {
        Text(viewModel.rateText)
            .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func secondaryLeading() -> some View {
        Text(viewModel.networkName)
            .style(Font.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.secondary)
            .lineLimit(1)
    }

    func secondaryTrailing() -> some View {
        HStack(spacing: textHorizontalSpacing) {
            viewModel.earnImageType.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
                .frame(width: earnImageSide, height: earnImageSide)

            Text(viewModel.earnType.rawValue)
                .style(Font.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.tertiary)
                .lineLimit(1)
        }
    }
}
