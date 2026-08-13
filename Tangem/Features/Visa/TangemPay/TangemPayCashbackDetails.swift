//
//  TangemPayCashbackDetails.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

struct TangemPayCashbackDetails: Equatable {
    static let currency = TangemPayUtilities.fiatItem.currencyCode

    let history: [MonthlyEarning]
    let totalEarned: Decimal
    let cashbackOnCards: CashbackOnCards?
    let additionalPromotions: [AdditionalPromotion]
    let accrualsDocs: [AccrualsDoc]
}

extension TangemPayCashbackDetails {
    struct MonthlyEarning: Equatable {
        let year: Int
        let month: Int
        let amount: Decimal
    }

    struct CashbackOnCards: Equatable {
        let tiers: [Tier]
        let accountMonthlyCap: Decimal?

        struct Tier: Equatable {
            let promotionId: String
            let kind: TierKind
            let rate: Decimal
            let minTransactionAmount: Decimal?
            let monthlyCap: Decimal?
        }
    }

    struct AdditionalPromotion: Equatable, Identifiable {
        let id: String
        let kind: TierKind
        let name: String
        let description: String?
        let endDate: Date?
        let cap: Cap?
        let minTransactionAmount: Decimal?

        struct Cap: Equatable {
            let amount: Decimal
            let period: Period

            enum Period: Equatable {
                case monthly
                case lifetime
            }
        }
    }

    struct AccrualsDoc: Equatable, Identifiable {
        let id: String
        let title: String
        let url: URL
    }

    enum TierKind: Equatable {
        case basic
        case plus
        case plusFF
        case unknown
    }
}

// MARK: - Mapping

extension TangemPayCashbackDetails {
    /// - Parameters:
    ///   - months: Size of the requested window. Months missing from `history` are filled with zeros
    ///   - referenceDate: The month the window ends on
    init(
        history: TangemPayCashbackHistoryResponse,
        promotions: TangemPayCashbackPromotionsResponse,
        accrualsDocs: TangemPayCashbackAccrualsDocsResponse,
        months: Int,
        referenceDate: Date
    ) {
        let earnings = Self.makeHistory(from: history, months: months, referenceDate: referenceDate)

        self.init(
            history: earnings,
            totalEarned: earnings.reduce(.zero) { $0 + $1.amount },
            cashbackOnCards: promotions.cashbackOnCards.map(CashbackOnCards.init),
            additionalPromotions: promotions.additionalCashback.map(AdditionalPromotion.init),
            accrualsDocs: accrualsDocs.docs.compactMap(AccrualsDoc.init)
        )
    }
}

private extension TangemPayCashbackDetails {
    static func makeHistory(
        from response: TangemPayCashbackHistoryResponse,
        months: Int,
        referenceDate: Date
    ) -> [MonthlyEarning] {
        let amountsByMonth = Dictionary(
            response.items.map { (MonthKey(year: $0.year, month: $0.month), decimal($0.confirmedAmount)) },
            uniquingKeysWith: { _, latest in latest }
        )

        return monthKeys(months: months, referenceDate: referenceDate).map { key in
            MonthlyEarning(
                year: key.year,
                month: key.month,
                amount: amountsByMonth[key] ?? .zero
            )
        }
    }

    static func monthKeys(months: Int, referenceDate: Date) -> [MonthKey] {
        guard months > 0 else {
            return []
        }

        let calendar = utcCalendar
        let referenceComponents = calendar.dateComponents([.year, .month], from: referenceDate)

        guard let referenceMonthStart = calendar.date(from: referenceComponents) else {
            return []
        }

        return (0 ..< months)
            .reversed()
            .compactMap { offset in
                guard let date = calendar.date(byAdding: .month, value: -offset, to: referenceMonthStart) else {
                    return nil
                }

                let components = calendar.dateComponents([.year, .month], from: date)

                guard let year = components.year, let month = components.month else {
                    return nil
                }

                return MonthKey(year: year, month: month)
            }
    }

    struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }()
}

private extension TangemPayCashbackDetails {
    static func decimal(_ string: String) -> Decimal {
        Decimal(stringValue: string) ?? .zero
    }

    static func optionalDecimal(_ string: String?) -> Decimal? {
        string.flatMap { Decimal(stringValue: $0) }
    }
}

private extension TangemPayCashbackDetails.CashbackOnCards {
    init(_ response: TangemPayCashbackPromotionsResponse.CashbackOnCards) {
        self.init(
            tiers: response.tiers.map(Tier.init),
            accountMonthlyCap: TangemPayCashbackDetails.optionalDecimal(response.accountMonthlyCapAmount)
        )
    }
}

private extension TangemPayCashbackDetails.CashbackOnCards.Tier {
    init(_ response: TangemPayCashbackPromotionsResponse.CashbackOnCards.Tier) {
        self.init(
            promotionId: response.promotionId,
            kind: TangemPayCashbackDetails.TierKind(response.tier),
            rate: TangemPayCashbackDetails.decimal(response.tierCashbackRate),
            minTransactionAmount: TangemPayCashbackDetails.optionalDecimal(response.minTransactionAmount),
            monthlyCap: TangemPayCashbackDetails.optionalDecimal(response.tierMonthlyCapAmount)
        )
    }
}

private extension TangemPayCashbackDetails.AdditionalPromotion {
    init(_ response: TangemPayCashbackPromotionsResponse.AdditionalCashback) {
        self.init(
            id: response.id,
            kind: TangemPayCashbackDetails.TierKind(response.tier),
            name: response.name,
            description: response.description,
            endDate: response.endDate.flatMap(Self.date(from:)),
            cap: Cap(response),
            minTransactionAmount: TangemPayCashbackDetails.optionalDecimal(response.minTransactionAmount)
        )
    }

    static func date(from string: String) -> Date? {
        isoFormatter.date(from: string)
            ?? isoFormatterWithoutFractionalSeconds.date(from: string)
            ?? fullDateFormatter.date(from: string)
    }

    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let isoFormatterWithoutFractionalSeconds = ISO8601DateFormatter()

    static let fullDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}

private extension TangemPayCashbackDetails.AdditionalPromotion.Cap {
    init?(_ response: TangemPayCashbackPromotionsResponse.AdditionalCashback) {
        guard let amount = TangemPayCashbackDetails.optionalDecimal(response.promoCapAmount),
              let period = Period(response.promoCapPeriod)
        else {
            return nil
        }

        self.init(amount: amount, period: period)
    }
}

private extension TangemPayCashbackDetails.AdditionalPromotion.Cap.Period {
    init?(_ period: TangemPayCashbackPromotionsResponse.CapPeriod?) {
        switch period {
        case .monthly:
            self = .monthly
        case .lifetime:
            self = .lifetime
        case .undefined, .none:
            return nil
        }
    }
}

private extension TangemPayCashbackDetails.AccrualsDoc {
    init?(_ response: TangemPayCashbackAccrualsDocsResponse.Doc) {
        guard let url = URL(string: response.url) else {
            return nil
        }

        self.init(id: response.id, title: response.title, url: url)
    }
}

private extension TangemPayCashbackDetails.TierKind {
    init(_ tier: TangemPayCashbackTier) {
        self = switch tier {
        case .basic: .basic
        case .plus: .plus
        case .plusFF: .plusFF
        case .undefined: .unknown
        }
    }
}
