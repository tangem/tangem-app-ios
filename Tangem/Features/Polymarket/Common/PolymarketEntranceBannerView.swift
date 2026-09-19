//
//  PolymarketEntranceBannerView.swift
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

struct PolymarketEntranceBannerView: View {
    @ScaledMetric private var iconSize: CGFloat = Constants.iconSize

    var body: some View {
        HStack(alignment: .center, spacing: Constants.spacing) {
            icon

            titleAndDescription
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .glowRing(.magic)
    }
}

private extension PolymarketEntranceBannerView {
    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: Constants.textSpacing) {
            // [REDACTED_TODO_COMMENT]
            Text(Constants.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.predictionAccountSubtitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    var icon: some View {
        Assets.Polymarket.accountAvatar.image
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
    }

    var background: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: Constants.borderWidth)
            )
    }
}

// MARK: - Constants

private extension PolymarketEntranceBannerView {
    enum Constants {
        static let title = "Polymarket"
        static let iconSize: CGFloat = 40
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 24
        static let borderWidth: CGFloat = 1
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
        PolymarketEntranceBannerView()
            .padding(.horizontal, 16)
    }
}
