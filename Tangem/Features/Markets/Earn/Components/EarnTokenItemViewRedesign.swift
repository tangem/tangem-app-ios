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
    private let viewModel: EarnTokenItemViewModel

    @ScaledSize private var tokenImageSize: CGSize
    @ScaledSize private var earnImageSize: CGSize
    @ScaledMetric private var textHorizontalSpacing: CGFloat
    @ScaledMetric private var horizontalPadding: CGFloat
    @ScaledMetric private var verticalPadding: CGFloat

    init(viewModel: EarnTokenItemViewModel) {
        self.viewModel = viewModel

        _tokenImageSize = ScaledSize(wrappedValue: CGSize(bothDimensions: .unit(.x10)))
        _earnImageSize = ScaledSize(wrappedValue: CGSize(bothDimensions: .unit(.x4)))
        _textHorizontalSpacing = ScaledMetric(wrappedValue: .unit(.x1))
        _horizontalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _verticalPadding = ScaledMetric(wrappedValue: .unit(.x3))
    }

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
            size: tokenImageSize,
            isWithOverlays: true,
            forceKingfisher: true
        )
    }

    func primaryLeading() -> some View {
        HStack(alignment: .lastTextBaseline, spacing: textHorizontalSpacing) {
            Text(viewModel.name)
                .style(.Tangem.Body15.semibold, color: .Tangem.Text.Neutral.primary)

            Text(viewModel.symbol)
                .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.secondary)
        }
        .lineLimit(1)
    }

    func primaryTrailing() -> some View {
        Text(viewModel.rateText)
            .style(.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func secondaryLeading() -> some View {
        Text(viewModel.networkName)
            .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.secondary)
            .lineLimit(1)
    }

    func secondaryTrailing() -> some View {
        HStack(spacing: textHorizontalSpacing) {
            viewModel.earnImageType.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
                .frame(size: earnImageSize)

            Text(viewModel.earnType.rawValue)
                .style(Font.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.tertiary)
                .lineLimit(1)
        }
    }
}
