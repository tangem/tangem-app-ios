//
//  TransactionDetailsYieldTokensView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TransactionDetailsYieldTokensViewData: Equatable {
    enum Provider: Equatable {
        case leading(ImageType)
        case trailing(ImageType)
    }

    let provider: Provider
    let tokenIconInfo: TokenIconInfo
    let amountText: String
    /// Caption above the amount describing the yield action (e.g. "Supplied" / "Returned").
    let caption: String?
    let fiatText: String?
    let isAmountStrikethrough: Bool
}

struct TransactionDetailsYieldTokensView: View {
    let data: TransactionDetailsYieldTokensViewData

    @ScaledMetric private var iconSide: CGFloat = 72
    @ScaledMetric private var overlap: CGFloat = 20
    @ScaledMetric private var ringWidth: CGFloat = 2

    private var artSize: CGSize {
        CGSize(bothDimensions: iconSide - 2 * ringWidth)
    }

    var body: some View {
        VStack(spacing: 24) {
            icons

            VStack(spacing: 4) {
                if let caption = data.caption {
                    Text(caption)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }

                VStack(spacing: 2) {
                    SensitiveText(data.amountText)
                        .strikethroughWhenVisible(data.isAmountStrikethrough)
                        .style(
                            DesignSystem.Font.headingMediumToken,
                            color: data.isAmountStrikethrough ? DesignSystem.Color.textTertiary : DesignSystem.Color.textPrimary
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    if let fiatText = data.fiatText {
                        SensitiveText(fiatText)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    @ViewBuilder
    private var icons: some View {
        switch data.provider {
        case .leading(let icon):
            pair(leading: providerIcon(icon), trailing: tokenIcon)
        case .trailing(let icon):
            pair(leading: tokenIcon, trailing: providerIcon(icon))
        }
    }

    private func pair(leading: some View, trailing: some View) -> some View {
        HStack(spacing: -overlap) {
            leading
                .zIndex(1)

            trailing
        }
    }

    private var tokenIcon: some View {
        TokenIcon(tokenIconInfo: data.tokenIconInfo, size: artSize, isWithOverlays: false)
            .frame(size: artSize)
            .clipShape(.circle)
            .ringed(width: ringWidth)
    }

    private func providerIcon(_ icon: ImageType) -> some View {
        icon.image
            .resizable()
            .scaledToFit()
            .frame(size: artSize)
            .ringed(width: ringWidth)
    }
}

private extension View {
    func ringed(width: CGFloat) -> some View {
        padding(width)
            .background(DesignSystem.Color.bgSecondary, in: Circle())
    }
}

// MARK: - Previews

#Preview("Supplied") {
    TransactionDetailsYieldTokensView(data: TransactionDetailsPreviewFactory.yieldSupplied())
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
}

#Preview("Returned") {
    TransactionDetailsYieldTokensView(data: TransactionDetailsPreviewFactory.yieldReturned())
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
}
