//
//  TangemPayCashbackDetailLoadedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayCashbackDetailLoadedView: View {
    let data: TangemPayCashbackDetailViewData
    let rateCardAction: () -> Void
    let accrualsCardAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                banner

                summaryCards

                chart

                additionalCashback
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Sections

private extension TangemPayCashbackDetailLoadedView {
    var header: some View {
        VStack(spacing: 4) {
            switch data.header {
            case .earned(let formattedAmount, let monthName, let payoutWindow):
                SensitiveText(
                    builder: { Localization.tangempayCashbackEarnedTitle($0, monthName) },
                    sensitive: formattedAmount
                )
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                if let payoutWindow {
                    Text(Localization.tangempayCashbackDepositedOn(payoutWindow))
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }

            case .empty:
                Text(Localization.tangempayCashbackEmptyTitle)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                Text(Localization.tangempayCashbackEmptySubtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 48)
    }

    @ViewBuilder
    var banner: some View {
        if let banner = data.banner {
            TangemPayCashbackInfoBanner(banner: banner)
                .padding(.bottom, 16)
        }
    }

    var summaryCards: some View {
        HStack(spacing: 8) {
            if let rateCard = data.rateCard {
                TangemPayCashbackInfoCard(
                    icon: DesignSystem.Icons.PercentBackward.regular20,
                    title: rateCard.title,
                    subtitle: rateCard.subtitle,
                    action: rateCardAction
                )
            }

            TangemPayCashbackInfoCard(
                icon: DesignSystem.Icons.Info.regular20,
                title: Localization.tangempayCashbackAccrualsTitle,
                subtitle: Localization.tangempayCashbackAccrualsSubtitle,
                action: accrualsCardAction
            )
        }
        .padding(.bottom, 16)
    }

    var chart: some View {
        TangemPayCashbackChartView(
            formattedTotal: data.chart.formattedTotal,
            items: data.chart.items,
            isZeroTotal: data.isEmpty
        )
        .padding(.bottom, 24)
    }

    @ViewBuilder
    var additionalCashback: some View {
        if !data.additionalPromotions.isEmpty {
            TangemPayCashbackAdditionalSection(promotions: data.additionalPromotions)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Single tier") {
    ScrollView {
        TangemPayCashbackDetailLoadedView(data: .preview, rateCardAction: {}, accrualsCardAction: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Multiple tiers") {
    ScrollView {
        TangemPayCashbackDetailLoadedView(data: .previewMultipleTiers, rateCardAction: {}, accrualsCardAction: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("No promotions") {
    ScrollView {
        TangemPayCashbackDetailLoadedView(data: .previewWithoutPromotions, rateCardAction: {}, accrualsCardAction: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Refund") {
    ScrollView {
        TangemPayCashbackDetailLoadedView(data: .previewWithRefund, rateCardAction: {}, accrualsCardAction: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Zero total") {
    ScrollView {
        TangemPayCashbackDetailLoadedView(data: .previewEmpty, rateCardAction: {}, accrualsCardAction: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
#endif
