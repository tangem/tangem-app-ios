//
//  YieldModePromoSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct YieldModePromoSheetView: View {
    let viewModel: YieldModePromoSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.title)
                    .style(
                        DesignSystem.Font.headingMediumToken,
                        color: DesignSystem.Color.textPrimary
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.subtitle)
                    .style(
                        DesignSystem.Font.bodyMediumToken,
                        color: DesignSystem.Color.textSecondary
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)

            tokensRow
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .footer {
            Footer(.buttons(primary: tryYieldModeButton))
        }
    }

    private var tokensRow: some View {
        HStack(spacing: 12) {
            Text(viewModel.tokensCountText)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            tokenIcons
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .background {
            let shadow = DesignSystem.Shadow.button

            Capsule()
                .fill(DesignSystem.Color.bgTransparentOnMaterialPrimary)
                .shadow(color: shadow.color, radius: shadow.blur / 2, y: shadow.offsetY)
        }
    }

    private var tokenIcons: some View {
        HStack(spacing: -Constants.tokenIconOverlap) {
            ForEach(indexed: viewModel.tokenIcons, id: \.0) { index, tokenIcon in
                TokenIconV2(tokenIconInfo: tokenIcon, size: .size40)
                    .clipShape(Circle())
                    .zIndex(Double(-index))
            }
        }
    }

    private var tryYieldModeButton: TangemUI.Button {
        TangemUI.Button(
            label: viewModel.actionTitle,
            accessibilityLabel: nil,
            action: viewModel.tryYieldMode
        )
        .styleType(.primary)
    }
}

// MARK: - Header

struct YieldModePromoSheetHeaderView: View {
    let viewModel: YieldModePromoSheetViewModel

    var body: some View {
        YieldModePromoSheetArtworkView(height: Constants.heroHeight)
            .overlay(alignment: .topTrailing) {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.close
                )
                .size(.x11)
                .styleType(.material(.glass))
                .padding(16)
            }
    }
}

// MARK: - Constants

private enum Constants {
    static let heroHeight: CGFloat = 274
    static let tokenIconOverlap: CGFloat = 12
}

// MARK: - Previews

#Preview {
    let viewModel = YieldModePromoSheetViewModel(
        data: YieldModePromoSheetData(
            apy: 0.0612,
            tokensCount: 12,
            tokenSymbol: "USDT",
            blockchainName: "Ethereum"
        ),
        routable: nil
    )

    Color.clear.modal(
        item: .constant(viewModel),
        header: { YieldModePromoSheetHeaderView(viewModel: $0) },
        content: { YieldModePromoSheetView(viewModel: $0) }
    )
}
