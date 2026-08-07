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
        let currency: String
        let period: Period
    }

    enum DisplayMode {
        case full
        case alternative
    }

    struct Period: Equatable {
        let year: Int
        let month: Int
        let payoutStartDate: Date
        let payoutEndDate: Date
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
              let currency = response.currency,
              let period = response.period.flatMap({ TangemPayCashback.Period($0) })
        else {
            return nil
        }

        self.init(
            displayMode: TangemPayCashback.DisplayMode(response.cashbackDisplayMode),
            confirmedAmount: confirmedAmount,
            currency: currency,
            period: period
        )
    }
}

private extension TangemPayCashback.Period {
    init?(_ period: TangemPayCashbackSummaryResponse.Period) {
        guard let payoutStartDate = Self.payoutDateFormatter.date(from: period.payoutStartDate),
              let payoutEndDate = Self.payoutDateFormatter.date(from: period.payoutEndDate)
        else {
            return nil
        }

        self.init(
            year: period.year,
            month: period.month,
            payoutStartDate: payoutStartDate,
            payoutEndDate: payoutEndDate
        )
    }

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
