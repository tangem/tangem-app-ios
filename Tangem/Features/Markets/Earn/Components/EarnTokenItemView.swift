//
//  EarnTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnTokenItemView: View {
    let viewModel: EarnTokenItemViewModel

    var body: some View {
        Button(action: {
            viewModel.onTapAction()
        }) {
            HStack(spacing: Layout.itemsHorizontalSpacing) {
                // Left: Token Icon
                tokenIconWithOverlay

                // Center: Token Name, Symbol, and Network
                VStack(alignment: .leading, spacing: Layout.textVerticalSpacing) {
                    // Token Name and Symbol on one line
                    HStack(alignment: .firstTextBaseline, spacing: Layout.nameSymbolSpacing) {
                        Text(viewModel.name)
                            .lineLimit(1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.symbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    }

                    // Network Name
                    Text(viewModel.networkName)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }

                Spacer()

                // Right: Rate (APY/APR) and Earn Type
                VStack(alignment: .trailing, spacing: Layout.textVerticalSpacing) {
                    Text(viewModel.rateText)
                        .lineLimit(1)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.accent)

                    Text(viewModel.earnType.rawValue)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
        }
    }

    private var tokenIconWithOverlay: some View {
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

private extension EarnTokenItemView {
    enum Layout {
        static let itemsHorizontalSpacing: CGFloat = 12.0
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 14.0
        static let textVerticalSpacing: CGFloat = 2.0
        static let nameSymbolSpacing: CGFloat = 4.0
        static let imageSize: CGSize = .init(bothDimensions: 36)
    }
}
