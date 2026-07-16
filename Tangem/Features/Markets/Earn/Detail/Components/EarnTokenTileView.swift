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
        Button(action: {
            viewModel.onTapAction()
        }) {
            VStack(alignment: .leading, spacing: 0.0) {
                redesignedTokenIcon

                FixedSpacer(height: 22.0)

                HStack(alignment: .firstBaselineCustom, spacing: .unit(.half)) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(Font.Tangem.Caption12.semibold, color: Color.Tangem.Text.Neutral.secondary)
                }

                FixedSpacer(height: .unit(.x1))

                Text(viewModel.rateText)
                    .lineLimit(1)
                    .style(Font.Tangem.Caption12.semibold, color: Color.Tangem.Text.Status.positive)
            }
            .frame(width: RedesignLayout.tileWidth, alignment: .topLeading)
            .padding(.bottom, .unit(.x1))
            .defaultRoundedBackground(
                with: .Tangem.Surface.level3,
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
            size: .init(bothDimensions: .unit(.x10)),
            isWithOverlays: true,
            forceKingfisher: true
        )
    }
}

// MARK: - Layout

private extension EarnTokenTileView {
    enum RedesignLayout {
        static let tileWidth: CGFloat = 150.0
        static let cornerRadius: CGFloat = .unit(.x6)
    }
}
