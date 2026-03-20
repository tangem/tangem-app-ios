//
//  EarnTokenTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnTokenTileView: View {
    let viewModel: EarnTokenItemViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignedContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesigned

    private var redesignedContent: some View {
        Button(action: {
            viewModel.onTapAction()
        }) {
            VStack(alignment: .leading, spacing: 0.0) {
                redesignedTokenIcon

                FixedSpacer(height: 22.0)

                HStack(alignment: .firstBaselineCustom, spacing: .unit(.half)) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(.Tangem.Body16.semibold, color: Color.Tangem.Text.Neutral.primary)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(.Tangem.Caption12.semibold, color: Color.Tangem.Text.Neutral.secondary)
                }

                FixedSpacer(height: .unit(.x1))

                Text(viewModel.rateText)
                    .lineLimit(1)
                    .style(.Tangem.Caption12.semibold, color: Color.Tangem.Text.Status.positive)
            }
            .frame(width: RedesignLayout.tileWidth, alignment: .topLeading)
            .background {
                blurredBackground
            }
            .padding(.bottom, .unit(.x1))
            .defaultRoundedBackground(
                with: Colors.Background.action,
                cornerRadius: RedesignLayout.cornerRadius
            )
            .clipShape(RoundedRectangle(cornerRadius: RedesignLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: RedesignLayout.cornerRadius)
                    .stroke(Color.Tangem.Border.Neutral.tertiary.opacity(0.1), lineWidth: 1.0)
            )
        }
        .buttonStyle(.plain)
    }

    private var blurredBackground: some View {
        IconView(
            url: viewModel.imageUrl,
            size: .init(bothDimensions: RedesignLayout.tileWidth),
            cornerRadius: 0,
            forceKingfisher: true
        )
        .blur(radius: 20.0)
        .opacity(0.5)
    }

    private var redesignedTokenIcon: some View {
        TokenIcon(
            tokenIconInfo: TokenIconInfo(
                name: viewModel.name,
                blockchainIconAsset: viewModel.isNativeToken ? nil : viewModel.blockchainIconAsset,
                imageURL: viewModel.imageUrl,
                isCustom: false,
                customTokenColor: nil,
                networkBorderColor: .clear
            ),
            size: .init(bothDimensions: .unit(.x10)),
            isWithOverlays: true,
            forceKingfisher: true
        )
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        Button(action: {
            viewModel.onTapAction()
        }) {
            VStack(alignment: .leading, spacing: LegacyLayout.verticalSpacing) {
                legacyTokenIcon

                FixedSpacer(height: LegacyLayout.iconTextVerticalSpacing)

                HStack(alignment: .firstBaselineCustom, spacing: LegacyLayout.textSpacing) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }

                FixedSpacer(height: LegacyLayout.textAPRVerticalSpacing)

                Text(viewModel.rateText)
                    .lineLimit(1)
                    .style(Fonts.Bold.caption1, color: Colors.Text.accent)
            }
            .frame(width: LegacyLayout.tileWidth, alignment: .topLeading)
            .defaultRoundedBackground(
                with: Colors.Background.action,
                cornerRadius: LegacyLayout.cornerRadius
            )
        }
        .buttonStyle(.plain)
    }

    private var legacyTokenIcon: some View {
        TokenIcon(
            tokenIconInfo: TokenIconInfo(
                name: viewModel.name,
                blockchainIconAsset: viewModel.blockchainIconAsset,
                imageURL: viewModel.imageUrl,
                isCustom: false,
                customTokenColor: nil
            ),
            size: LegacyLayout.imageSize,
            isWithOverlays: true,
            forceKingfisher: true
        )
    }
}

// MARK: - Layout

private extension EarnTokenTileView {
    enum RedesignLayout {
        static let tileWidth: CGFloat = 150.0
        static let cornerRadius: CGFloat = .unit(.x5)
    }

    enum LegacyLayout {
        static let tileWidth: CGFloat = 120.0
        static let verticalSpacing: CGFloat = 0.0
        static let iconTextVerticalSpacing: CGFloat = 12.0
        static let textAPRVerticalSpacing: CGFloat = 2.0
        static let textSpacing: CGFloat = 2.0
        static let imageSize: CGSize = .init(bothDimensions: 32)
        static let cornerRadius: CGFloat = 14.0
    }
}
