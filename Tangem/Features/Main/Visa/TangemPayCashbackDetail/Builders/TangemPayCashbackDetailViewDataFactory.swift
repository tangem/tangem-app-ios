//
//  TangemPayCashbackDetailViewDataFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay
import TangemVisa
import TangemLocalization

struct TangemPayCashbackDetailViewDataFactory {
    private let amountFormatter = TangemPayFiatAmountFormatter()

    func make(
        details: TangemPayCashbackDetails,
        summary: TangemPayCashback.Summary
    ) -> TangemPayCashbackDetailViewData {
        TangemPayCashbackDetailViewData(
            header: makeHeader(details: details, summary: summary),
            banner: makeBanner(summary: summary),
            rateCard: makeRateCard(cashbackOnCards: details.cashbackOnCards),
            chart: makeChart(details: details, summary: summary),
            additionalPromotions: details.additionalPromotions.map(makePromotion)
        )
    }
}

// MARK: - Sections

private extension TangemPayCashbackDetailViewDataFactory {
    func makeHeader(
        details: TangemPayCashbackDetails,
        summary: TangemPayCashback.Summary
    ) -> TangemPayCashbackDetailViewData.Header {
        guard details.totalEarned != .zero else {
            return .empty
        }

        return .earned(
            formattedAmount: formattedFiat(summary.confirmedAmount, currency: summary.currency),
            monthName: TangemPayCashbackState.monthName(summary.period.month),
            payoutWindow: summary.confirmedAmount > 0 ? payoutWindow(for: summary) : nil
        )
    }

    func makeBanner(summary: TangemPayCashback.Summary) -> TangemPayCashbackDetailViewData.Banner? {
        if summary.confirmedAmount > 0 {
            guard let payoutEndDate = summary.period.payoutEndDate else {
                return nil
            }

            return .deposit(
                formattedAmount: formattedFiat(summary.confirmedAmount, currency: summary.currency),
                monthName: TangemPayCashbackState.monthName(summary.period.month),
                payoutDate: Self.payoutDateFormatter.string(from: payoutEndDate)
            )
        }

        return summary.confirmedAmount < 0 ? .refund : nil
    }

    func makeRateCard(
        cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards?
    ) -> TangemPayCashbackDetailViewData.RateCard? {
        guard let cashbackOnCards,
              let title = rateTitle(for: cashbackOnCards),
              let topTier = topTier(of: cashbackOnCards)
        else {
            return nil
        }

        return TangemPayCashbackDetailViewData.RateCard(
            title: title,
            subtitle: topTier.kind.planName.map(Localization.tangempayCashbackRateSubtitle)
        )
    }

    func rateTitle(for cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards) -> String? {
        guard let topTier = topTier(of: cashbackOnCards) else {
            return nil
        }

        let rate = formattedRate(topTier.rate)

        return cashbackOnCards.tiers.count == 1
            ? Localization.tangempayCashbackRateTitle(rate)
            : Localization.tangempayCashbackRateTitleUpTo(rate)
    }

    func topTier(of cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards) -> TangemPayCashbackDetails.CashbackOnCards.Tier? {
        cashbackOnCards.tiers.max { $0.rate < $1.rate }
    }

    func makeChart(
        details: TangemPayCashbackDetails,
        summary: TangemPayCashback.Summary
    ) -> TangemPayCashbackDetailViewData.Chart {
        let items = details.history.map { earning in
            TangemPayCashbackChartView.Item(
                month: shortMonthName(earning.month),
                value: earning.amount,
                formattedValue: formattedFiat(earning.amount, currency: TangemPayCashbackDetails.currency),
                isSelected: earning.year == summary.period.year && earning.month == summary.period.month
            )
        }

        return TangemPayCashbackDetailViewData.Chart(
            formattedTotal: formattedFiat(details.totalEarned, currency: TangemPayCashbackDetails.currency),
            items: items
        )
    }

    func makePromotion(
        _ promotion: TangemPayCashbackDetails.AdditionalPromotion
    ) -> TangemPayCashbackDetailViewData.AdditionalPromotion {
        TangemPayCashbackDetailViewData.AdditionalPromotion(
            id: promotion.id,
            badge: makeBadge(endDate: promotion.endDate),
            title: promotion.name,
            subtitle: subtitle(for: promotion)
        )
    }

    func makeBadge(endDate: Date?) -> TangemPayCashbackDetailViewData.AdditionalPromotion.Badge {
        guard let endDate else {
            return .init(label: Localization.tangempayCashbackAdditionalPermanent, isTimeLimited: false)
        }

        return .init(
            label: Localization.tangempayCashbackAdditionalUntil(Self.endDateFormatter.string(from: endDate)),
            isTimeLimited: true
        )
    }

    func subtitle(for promotion: TangemPayCashbackDetails.AdditionalPromotion) -> String? {
        let description = promotion.description?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let cap = promotion.cap, cap.period == .monthly else {
            return description
        }

        let capSentence = Localization.tangempayCashbackDetailsCap(
            formattedFiat(cap.amount, currency: TangemPayCashbackDetails.currency)
        )

        guard let description, !description.isEmpty else {
            return capSentence
        }

        let separator = description.hasSuffix(".") ? " " : ". "

        return description + separator + capSentence
    }
}

// MARK: - Tier naming

private extension TangemPayCashbackDetails.TierKind {
    var planName: String? {
        switch self {
        case .basic: "Basic"
        case .plus: "Plus"
        case .plusFF: "Plus FF"
        case .unknown: nil
        }
    }
}

// MARK: - Formatting

private extension TangemPayCashbackDetailViewDataFactory {
    func formattedFiat(_ amount: Decimal, currency: String) -> String {
        amountFormatter.format(amount, currencyCode: currency)
    }

    func formattedRate(_ rate: Decimal) -> String {
        Self.rateFormatter.string(from: rate as NSDecimalNumber) ?? "\(rate)"
    }

    func shortMonthName(_ month: Int) -> String {
        let symbols = Self.shortMonthSymbols

        return symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
    }

    func payoutWindow(for summary: TangemPayCashback.Summary) -> String? {
        guard let start = summary.period.payoutStartDate, let end = summary.period.payoutEndDate else {
            return nil
        }

        return Self.payoutWindowFormatter.string(from: DateInterval(start: start, end: end))
    }

    static let shortMonthSymbols = DateFormatter().shortMonthSymbols ?? []

    static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let payoutWindowFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateTemplate = "MMMMd"
        return formatter
    }()

    static let payoutDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter
    }()

    static let endDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
