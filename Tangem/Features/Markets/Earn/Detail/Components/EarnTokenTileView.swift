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

    @ScaledMetric private var tileWidth: CGFloat = RedesignLayout.tileWidth

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

                HStack(alignment: .firstBaselineCustom, spacing: RedesignLayout.textSpacing) {
                    Text(viewModel.name)
                        .lineLimit(1)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(viewModel.symbol)
                        .lineLimit(1)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }

                FixedSpacer(height: 4)

                HStack(spacing: RedesignLayout.textSpacing) {
                    Text(viewModel.rateText)
                        .lineLimit(1)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentGreen)

                    Text(viewModel.earnType.title)
                        .lineLimit(1)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .frame(width: tileWidth, alignment: .topLeading)
            .padding(.bottom, 4)
            .defaultRoundedBackground(
                with: DesignSystem.Color.bgTransparentPrimary,
                verticalPadding: RedesignLayout.verticalPadding,
                horizontalPadding: RedesignLayout.horizontalPadding,
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
        static let tileWidth: CGFloat = 154.0
        static let verticalPadding: CGFloat = 12.0
        static let horizontalPadding: CGFloat = 12.0
        static let textSpacing: CGFloat = 4.0
        static let cornerRadius: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    func tile(name: String, symbol: String, networkId: String, rate: String, earnType: EarnType) -> EarnTokenTileView {
        EarnTokenTileView(
            viewModel: EarnTokenItemViewModel(
                token: EarnTokenModel(
                    id: symbol.lowercased(),
                    name: name,
                    symbol: symbol,
                    imageUrl: nil,
                    networkId: networkId,
                    networkName: networkId.capitalized,
                    blockchainIconAsset: nil,
                    contractAddress: nil,
                    decimalCount: nil,
                    rateValue: 0,
                    rateType: .apy,
                    rateText: rate,
                    earnType: earnType
                ),
                onTapAction: {}
            )
        )
    }

    return HStack(spacing: 8) {
        tile(name: "Solana", symbol: "SOL", networkId: "solana", rate: "APY 19.44%", earnType: .staking)
        tile(name: "Dai", symbol: "DAI", networkId: "ethereum", rate: "APY 5.00%", earnType: .yieldMode)
    }
    .padding()
}
