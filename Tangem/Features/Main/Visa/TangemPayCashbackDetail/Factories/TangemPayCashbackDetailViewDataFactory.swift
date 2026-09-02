//
//  TangemPayCashbackDetailViewDataFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
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

    func makeTiersViewData(
        cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards,
        payoutCurrency: String
    ) -> TangemPayCashbackTiersViewData {
        TangemPayCashbackTiersViewData(
            title: rateTitle(for: cashbackOnCards) ?? Localization.tangempayCashbackTitle,
            rows: makeTiersRows(cashbackOnCards: cashbackOnCards, payoutCurrency: payoutCurrency)
        )
    }

    func makeAccrualsViewData(docs: [TangemPayCashbackDetails.AccrualsDoc]) -> TangemPayCashbackAccrualsViewData {
        TangemPayCashbackAccrualsViewData(
            docs: docs.map { TangemPayCashbackAccrualsViewData.Doc(id: $0.id, title: $0.title, url: $0.url) }
        )
    }
}

// MARK: - Markdown

extension TangemPayCashbackDetailViewDataFactory {
    static func makeMarkdown(_ string: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)

        guard var attributed = try? AttributedString(markdown: string, options: options) else {
            return AttributedString(string)
        }

        for run in attributed.runs where run.link != nil {
            attributed[run.range].underlineStyle = Text.LineStyle.single
            attributed[run.range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return attributed
    }
}

// MARK: - Sections

private extension TangemPayCashbackDetailViewDataFactory {
    func makeHeader(
        details: TangemPayCashbackDetails,
        summary: TangemPayCashback.Summary
    ) -> TangemPayCashbackDetailViewData.Header {
        guard summary.totalEarnedAmount != .zero else {
            return .empty
        }

        return .earned(
            formattedAmount: formattedFiat(summary.confirmedAmount, currency: summary.currency),
            monthName: TangemPayCashbackState.monthName(summary.period.month),
            payoutWindow: summary.confirmedAmount < 0 ? nil : payoutWindow(for: summary)
        )
    }

    func makeBanner(summary: TangemPayCashback.Summary) -> TangemPayCashbackDetailViewData.Banner? {
        if summary.confirmedAmount < 0 {
            return .refund
        }

        guard let previousPayout = summary.previousPayout,
              previousPayout.amount > 0,
              isPayoutUpcoming(endDate: previousPayout.endDate),
              let earnedMonth = month(precedingPayoutDate: previousPayout.endDate)
        else {
            return nil
        }

        return .deposit(
            formattedAmount: formattedFiat(previousPayout.amount, currency: summary.currency),
            monthName: TangemPayCashbackState.monthName(earnedMonth),
            payoutDate: Self.payoutDateFormatter.string(from: previousPayout.endDate)
        )
    }

    func isPayoutUpcoming(endDate: Date, now: Date = .now) -> Bool {
        let calendar = Self.utcCalendar

        guard let deadline = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            return false
        }

        return now < deadline
    }

    func month(precedingPayoutDate date: Date) -> Int? {
        let calendar = Self.utcCalendar

        guard let earnedMonthDate = calendar.date(byAdding: .month, value: -1, to: date) else {
            return nil
        }

        return calendar.component(.month, from: earnedMonthDate)
    }

    func makeRateCard(
        cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards?
    ) -> TangemPayCashbackDetailViewData.RateCard? {
        guard let cashbackOnCards,
              let title = rateTitle(for: cashbackOnCards),
              let topCard = topCard(of: cashbackOnCards)
        else {
            return nil
        }

        return TangemPayCashbackDetailViewData.RateCard(
            title: title,
            subtitle: Localization.tangempayCashbackRateSubtitle(topCard.title)
        )
    }

    func rateTitle(for cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards) -> String? {
        guard let topCard = topCard(of: cashbackOnCards) else {
            return nil
        }

        let rate = formattedRate(topCard.rate)

        return cashbackOnCards.cards.count == 1
            ? Localization.tangempayCashbackRateTitle(rate)
            : Localization.tangempayCashbackRateTitleUpTo(rate)
    }

    func topCard(of cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards) -> TangemPayCashbackDetails.CashbackOnCards.Card? {
        cashbackOnCards.cards.max { $0.rate < $1.rate }
    }

    func makeTiersRows(
        cashbackOnCards: TangemPayCashbackDetails.CashbackOnCards,
        payoutCurrency: String
    ) -> [TangemPayCashbackTiersViewData.Row] {
        var rows = cashbackOnCards.cards
            .sorted { $0.rate < $1.rate }
            .compactMap { card -> TangemPayCashbackTiersViewData.Row? in
                guard let minTransactionAmount = card.minTransactionAmount else {
                    return nil
                }

                return TangemPayCashbackTiersViewData.Row(
                    id: card.promotionId,
                    text: Localization.tangempayCashbackDetailsTier(
                        formattedRate(card.rate),
                        card.title,
                        formattedFiat(
                            minTransactionAmount,
                            currency: TangemPayCashbackDetails.currency,
                            hidesFractionForWholeAmounts: true
                        )
                    )
                )
            }

        rows.append(
            TangemPayCashbackTiersViewData.Row(
                id: Constants.euExcludedRowId,
                text: Localization.tangempayCashbackDetailsEuExcluded
            )
        )

        rows.append(
            TangemPayCashbackTiersViewData.Row(
                id: Constants.paidInRowId,
                text: Localization.tangempayCashbackDetailsPaidIn(payoutCurrency)
            )
        )

        if let capCurrency = cashbackOnCards.accountMonthlyCapCurrency,
           let accountMonthlyCap = cashbackOnCards.accountMonthlyCap,
           accountMonthlyCap > 0 {
            rows.append(
                TangemPayCashbackTiersViewData.Row(
                    id: Constants.capRowId,
                    text: Localization.tangempayCashbackDetailsCap(
                        formattedFiat(accountMonthlyCap, currency: capCurrency, hidesFractionForWholeAmounts: true)
                    )
                )
            )
        }

        return rows
    }

    enum Constants {
        static let euExcludedRowId = "eu-excluded"
        static let paidInRowId = "paid-in"
        static let capRowId = "cap"
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
            formattedTotal: formattedFiat(
                summary.totalEarnedAmount,
                currency: summary.currency,
                hidesFractionForWholeAmounts: true
            ),
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

    func subtitle(for promotion: TangemPayCashbackDetails.AdditionalPromotion) -> AttributedString? {
        guard let description = promotion.description else {
            return nil
        }

        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        return Self.makeMarkdown(trimmed)
    }
}

// MARK: - Formatting

private extension TangemPayCashbackDetailViewDataFactory {
    func formattedFiat(_ amount: Decimal, currency: String, hidesFractionForWholeAmounts: Bool = false) -> String {
        amountFormatter.format(
            amount,
            currencyCode: currency,
            hidesFractionForWholeAmounts: hidesFractionForWholeAmounts
        )
    }

    func formattedRate(_ rate: Decimal) -> String {
        Self.rateFormatter.string(from: rate as NSDecimalNumber) ?? "\(rate)"
    }

    func shortMonthName(_ month: Int) -> String {
        let symbols = Self.shortStandaloneMonthSymbols

        return symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
    }

    func payoutWindow(for summary: TangemPayCashback.Summary) -> String? {
        guard let start = summary.period.payoutStartDate, let end = summary.period.payoutEndDate else {
            return nil
        }

        return Self.payoutWindowFormatter.string(from: DateInterval(start: start, end: end))
    }

    static let shortStandaloneMonthSymbols = DateFormatter().shortStandaloneMonthSymbols ?? []

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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }()
}
