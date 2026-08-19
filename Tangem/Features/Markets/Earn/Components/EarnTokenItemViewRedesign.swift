//
//  EarnTokenItemViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct EarnTokenItemViewRedesign: View {
    let viewModel: EarnTokenItemViewModel

    @ScaledMetric private var tokenImageSide: CGFloat = 40
    @ScaledMetric private var earnImageSide: CGFloat = 16
    @ScaledMetric private var textHorizontalSpacing: CGFloat = 4
    @ScaledMetric private var horizontalPadding: CGFloat = 12
    @ScaledMetric private var verticalPadding: CGFloat = 12

    var body: some View {
        SwiftUI.Button(action: viewModel.onTapAction) {
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
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.symbol)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .lineLimit(1)
    }

    func primaryTrailing() -> some View {
        Text(viewModel.rateText)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    func secondaryLeading() -> some View {
        Text(viewModel.networkName)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }

    func secondaryTrailing() -> some View {
        HStack(spacing: textHorizontalSpacing) {
            viewModel.earnImageType.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: earnImageSide, height: earnImageSide)

            Text(viewModel.earnType.rawValue)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
        }
    }
}
