//
//  TangemPayTransactionCashback.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

enum TangemPayTransactionCashback: Equatable {
    case earned(amount: Decimal, currency: String)
    case excluded(reason: ExclusionReason?)
}

extension TangemPayTransactionCashback {
    enum ExclusionReason: Equatable {
        case merchantCountry
        case mcc
        case belowMin
        case monthlyCap
    }
}

// MARK: - Mapping

extension TangemPayTransactionCashback {
    init?(_ response: TangemPayCashbackTransactionDetailsResponse) {
        guard let cashback = response.cashback else {
            return nil
        }

        switch cashback.status {
        case .estimated, .confirmed:
            guard let amount = Decimal(stringValue: cashback.amount), let currency = cashback.currency else {
                return nil
            }

            self = .earned(amount: amount, currency: currency)

        case .excluded:
            self = .excluded(reason: cashback.exclusionReason.flatMap(ExclusionReason.init))

        case .awaitingCalculation, .undefined:
            return nil
        }
    }
}

private extension TangemPayTransactionCashback.ExclusionReason {
    init?(_ reason: TangemPayCashbackTransactionDetailsResponse.ExclusionReason) {
        switch reason {
        case .merchantCountryExcluded:
            self = .merchantCountry
        case .mccExcluded:
            self = .mcc
        case .belowMin:
            self = .belowMin
        case .monthlyCapReached:
            self = .monthlyCap
        case .undefined:
            return nil
        }
    }
}
