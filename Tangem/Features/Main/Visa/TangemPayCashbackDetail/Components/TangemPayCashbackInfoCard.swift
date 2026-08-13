//
//  TangemPayCashbackInfoCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct TangemPayCashbackInfoCard: View {
    let icon: ImageType
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            iconView

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Subviews

private extension TangemPayCashbackInfoCard {
    var iconView: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgOpaquePrimary)

            icon.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        TangemPayCashbackInfoCard(
            icon: DesignSystem.Icons.PercentBackward.regular20,
            title: "Cashback 1%",
            subtitle: "With your Basic plan"
        )

        TangemPayCashbackInfoCard(
            icon: DesignSystem.Icons.Info.regular20,
            title: "Accruals",
            subtitle: "Limits and exceptions"
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
