//
//  TangemPayCashbackAdditionalRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct TangemPayCashbackAdditionalRow: View {
    let promotion: TangemPayCashbackDetailViewData.AdditionalPromotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            badge

            VStack(alignment: .leading, spacing: 2) {
                Text(promotion.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                if let subtitle = promotion.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
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

private extension TangemPayCashbackAdditionalRow {
    @ViewBuilder
    var badge: some View {
        if promotion.badge.isTimeLimited {
            Badge(label: promotion.badge.label, accessibilityLabel: nil)
                .appearance(.info)
                .slotStart(DesignSystem.Icons.Clock.regular16)
        } else {
            Badge(label: promotion.badge.label, accessibilityLabel: nil)
                .appearance(.neutral)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        ForEach(TangemPayCashbackDetailViewData.preview.additionalPromotions) { promotion in
            TangemPayCashbackAdditionalRow(promotion: promotion)
        }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
#endif
