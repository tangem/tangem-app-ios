//
//  TangemPayCashback.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

enum TangemPayCashback: Equatable {
    case available(Summary)
    case unavailable
    case blocked
}

extension TangemPayCashback {
    struct Summary: Equatable {
        let displayMode: DisplayMode
        let confirmedAmount: Decimal
        let totalEarnedAmount: Decimal
        let currency: String
        let payoutCurrency: String
        let period: Period
        let previousPayout: PreviousPayout?
    }

    enum DisplayMode {
        case full
        case alternative
    }

    struct Period: Equatable {
        let year: Int
        let month: Int
        let payoutStartDate: Date?
        let payoutEndDate: Date?
    }

    struct PreviousPayout: Equatable {
        let amount: Decimal
        let endDate: Date
    }
}

// MARK: - Mapping

extension TangemPayCashback {
    init(_ response: TangemPayCashbackSummaryResponse) {
        switch response.cashbackProgramStatus {
        case .fraud:
            self = .blocked

        case .disabled, .undefined:
            self = .unavailable

        case .enabled:
            guard let summary = Summary(response) else {
                self = .unavailable
                return
            }

            self = .available(summary)
        }
    }
}

private extension TangemPayCashback.Summary {
    init?(_ response: TangemPayCashbackSummaryResponse) {
        guard let confirmedAmount = Decimal(stringValue: response.confirmedAmount),
              let totalEarnedAmount = Decimal(stringValue: response.totalEarnedAmount),
              let currency = response.currency,
              let payoutCurrency = response.payoutCurrency,
              let period = response.period.map(TangemPayCashback.Period.init)
        else {
            return nil
        }

        self.init(
            displayMode: TangemPayCashback.DisplayMode(response.cashbackDisplayMode),
            confirmedAmount: confirmedAmount,
            totalEarnedAmount: totalEarnedAmount,
            currency: currency,
            payoutCurrency: payoutCurrency,
            period: period,
            previousPayout: TangemPayCashback.PreviousPayout(response)
        )
    }
}

private extension TangemPayCashback.Period {
    init(_ period: TangemPayCashbackSummaryResponse.Period) {
        self.init(
            year: period.year,
            month: period.month,
            payoutStartDate: period.payoutStartDate.flatMap(TangemPayCashback.payoutDateFormatter.date(from:)),
            payoutEndDate: period.payoutEndDate.flatMap(TangemPayCashback.payoutDateFormatter.date(from:))
        )
    }
}

private extension TangemPayCashback.PreviousPayout {
    init?(_ response: TangemPayCashbackSummaryResponse) {
        guard let amount = Decimal(stringValue: response.previousPayoutAmount),
              let endDate = response.previousPayoutEndDate.flatMap(TangemPayCashback.payoutDateFormatter.date(from:))
        else {
            return nil
        }

        self.init(amount: amount, endDate: endDate)
    }
}

private extension TangemPayCashback {
    static let payoutDateFormatter: DateFormatter = {
        let formatter = DateFormatter(dateFormat: "yyyy-MM-dd")
        formatter.locale = .posixEnUS
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

private extension TangemPayCashback.DisplayMode {
    init(_ mode: TangemPayCashbackSummaryResponse.Mode?) {
        self = switch mode {
        case .altBlock:
            .alternative
        case .full, .undefined, .none:
            .full
        }
    }
}
