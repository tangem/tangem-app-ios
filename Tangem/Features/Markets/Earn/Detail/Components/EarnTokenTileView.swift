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
        redesignedContent
    }

    // MARK: - Redesigned

    private var redesignedContent: some View {
        SwiftUI.Button(action: {
            viewModel.onTapAction()
        }) {
            VStack(alignment: .leading, spacing: 0.0) {
                redesignedTokenIcon

                FixedSpacer(height: 22.0)

                HStack(alignment: .firstBaselineCustom, spacing: 2) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }

                FixedSpacer(height: 4)

                Text(viewModel.rateText)
                    .lineLimit(1)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentGreen)
            }
            .frame(width: RedesignLayout.tileWidth, alignment: .topLeading)
            .padding(.bottom, 4)
            .defaultRoundedBackground(
                with: DesignSystem.Color.bgSecondary,
                cornerRadius: RedesignLayout.cornerRadius
            )
        }
        .buttonStyle(.plain)
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
            size: .init(bothDimensions: 40),
            isWithOverlays: true,
            forceKingfisher: true
        )
    }
}

// MARK: - Layout

private extension EarnTokenTileView {
    enum RedesignLayout {
        static let tileWidth: CGFloat = 150.0
        static let cornerRadius: CGFloat = 24
    }
}
