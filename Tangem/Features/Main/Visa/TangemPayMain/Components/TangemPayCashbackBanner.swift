//
//  TangemPayCashbackBanner.swift
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

struct TangemPayCashbackBanner: View {
    let state: TangemPayCashbackState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                titleView

                if let subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            indicatorView
        }
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .disabled(isReloading)
        .onTapGesture(perform: action)
    }
}

// MARK: - Content

private extension TangemPayCashbackBanner {
    var isReloading: Bool {
        guard case .failed(let isReloading) = state else {
            return false
        }

        return isReloading
    }

    var subtitle: String? {
        switch state {
        case .content(let summary):
            guard summary.confirmedAmount > 0 else {
                return nil
            }

            return Localization.tangempayCashbackDepositedOn(payoutWindow(for: summary))

        case .failed:
            return Localization.tangempayCashbackWidgetErrorDescription
        }
    }

    func formattedAmount(for summary: TangemPayCashback.Summary) -> String {
        BalanceFormatter().formatFiatBalance(
            summary.confirmedAmount,
            currencyCode: summary.currency
        )
    }

    static let payoutWindowFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateTemplate = "MMMMd"
        return formatter
    }()

    func payoutWindow(for summary: TangemPayCashback.Summary) -> String {
        let start = summary.period.payoutStartDate
        let end = summary.period.payoutEndDate
        let interval = DateInterval(start: start, end: end)

        return Self.payoutWindowFormatter.string(from: interval) ?? ""
    }
}

// MARK: - Subviews

private extension TangemPayCashbackBanner {
    @ViewBuilder
    var titleView: some View {
        switch state {
        case .content(let summary):
            SensitiveText(
                builder: { Localization.tangempayCashbackWidgetTitle($0, TangemPayCashbackState.monthName(summary.period.month)) },
                sensitive: formattedAmount(for: summary)
            )
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

        case .failed:
            Text(Localization.tangempayCashbackWidgetErrorTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        }
    }

    var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)

            icon(iconImage, color: iconForegroundColor)
        }
        .frame(width: 40, height: 40)
    }

    var indicatorView: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgOpaquePrimary)

            indicatorContent
        }
        .frame(width: 40, height: 40)
    }

    @ViewBuilder
    var indicatorContent: some View {
        switch state {
        case .content:
            icon(DesignSystem.Icons.ChevronRight.regular20, color: DesignSystem.Color.iconPrimary)

        case .failed(let isReloading):
            if isReloading {
                Loader()
                    .loaderSize(.size20)
                    .loaderColor(DesignSystem.Color.iconPrimary)
            } else {
                icon(DesignSystem.Icons.ArrowRefresh.regular20, color: DesignSystem.Color.iconPrimary)
            }
        }
    }

    func icon(_ image: ImageType, color: Color) -> some View {
        image.image
            .renderingMode(.template)
            .foregroundStyle(color)
    }

    var iconImage: ImageType {
        switch state {
        case .content: DesignSystem.Icons.PercentBackward.regular20
        case .failed: DesignSystem.Icons.Error.regular20
        }
    }

    var iconBackgroundColor: Color {
        if case .content(let summary) = state,
           summary.confirmedAmount >= 0 {
            return DesignSystem.Color.bgStatusInfoSubtle
        }

        return DesignSystem.Color.bgStatusErrorSubtle
    }

    var iconForegroundColor: Color {
        if case .content(let summary) = state,
           summary.confirmedAmount >= 0 {
            return DesignSystem.Color.iconBrand
        }

        return DesignSystem.Color.iconStatusError
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        TangemPayCashbackBanner(state: .content(.preview(confirmedAmount: 32.15)), action: {})

        TangemPayCashbackBanner(state: .content(.preview(confirmedAmount: 0)), action: {})

        TangemPayCashbackBanner(state: .content(.preview(confirmedAmount: -3.12)), action: {})

        TangemPayCashbackBanner(state: .failed(isReloading: false), action: {})

        TangemPayCashbackBanner(state: .failed(isReloading: true), action: {})
    }
    .padding(16)
}

private extension TangemPayCashback.Summary {
    static func preview(confirmedAmount: Decimal) -> Self {
        Self(
            displayMode: .full,
            confirmedAmount: confirmedAmount,
            currency: "USD",
            period: TangemPayCashback.Period(
                year: 2026,
                month: 6,
                payoutStartDate: .previewUTCDate(year: 2026, month: 7, day: 2),
                payoutEndDate: .previewUTCDate(year: 2026, month: 7, day: 5)
            )
        )
    }
}

private extension Date {
    static func previewUTCDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
#endif
