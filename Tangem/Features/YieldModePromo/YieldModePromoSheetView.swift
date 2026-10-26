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
                        DesignSystem.Font.subheadingMediumToken,
                        color: DesignSystem.Color.textSecondary
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.padding)
            .padding(.bottom, 20)

            tokensRow
                .padding(.horizontal, Constants.padding)
        }
        .onDisappear(perform: viewModel.onDisappear)
        .footer {
            Footer(.buttons(primary: tryYieldModeButton))
        }
    }

    private var tokensRow: some View {
        HStack(spacing: 12) {
            Text(viewModel.tokensCountText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // [REDACTED_TODO_COMMENT]
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Color.bgSecondary, in: Capsule())
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
                .padding(Constants.padding)
            }
    }
}

// MARK: - Constants

private enum Constants {
    static let heroHeight: CGFloat = 220
    static let padding: CGFloat = 16
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
