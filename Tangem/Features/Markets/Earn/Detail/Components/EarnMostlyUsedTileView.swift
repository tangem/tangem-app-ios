//
//  EarnMostlyUsedTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnMostlyUsedTileView: View {
    let viewModel: EarnTokenItemViewModel

    var body: some View {
        Button(action: {
            viewModel.onTapAction()
        }) {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                // Token Icon
                tokenIcon

                FixedSpacer(height: Layout.iconTextVerticalSpacing)

                // Token Name and Symbol
                HStack(alignment: .firstBaselineCustom, spacing: Layout.textSpacing) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }

                FixedSpacer(height: Layout.textAPRVerticalSpacing)

                // Rate (APY/APR)
                Text(viewModel.rateText)
                    .lineLimit(1)
                    .style(Fonts.Bold.caption1, color: Colors.Text.accent)
            }
            .frame(width: Layout.tileWidth, alignment: .topLeading)
            .defaultRoundedBackground(
                with: Colors.Background.action,
                cornerRadius: Layout.cornerRadius
            )
        }
        .buttonStyle(.plain)
    }

    private var tokenIcon: some View {
        TokenIcon(
            tokenIconInfo: TokenIconInfo(
                name: viewModel.name,
                blockchainIconAsset: nil,
                imageURL: viewModel.imageUrl,
                isCustom: false,
                customTokenColor: nil
            ),
            size: Layout.imageSize,
            isWithOverlays: false,
            forceKingfisher: true
        )
    }
}

private extension EarnMostlyUsedTileView {
    enum Layout {
        static let tileWidth: CGFloat = 120.0
        static let paddingHorizontal: CGFloat = 14.0
        static let paddingVertical: CGFloat = 12.0
        static let verticalSpacing: CGFloat = 0.0
        static let iconTextVerticalSpacing: CGFloat = 12.0
        static let textAPRVerticalSpacing: CGFloat = 2.0
        static let textSpacing: CGFloat = 2.0
        static let imageSize: CGSize = .init(bothDimensions: 32)
        static let cornerRadius: CGFloat = 14.0
    }
}
