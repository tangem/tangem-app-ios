//
//  PolymarketBalanceBlockAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUIUtils

struct PolymarketBalanceBlockAlertBuilder {
    func makeAddFundsUnavailableAlert(onRetry: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeOkGotItAlert(
            message: Localization.predictionAddFundsErrorDescription,
            okAction: onRetry
        )
    }

    func makeWithdrawUnavailableAlert(
        reason: PolymarketBalanceBlockViewModel.WithdrawUnavailability,
        onRetry: @escaping () -> Void
    ) -> AlertBinder {
        AlertBuilder.makeOkGotItAlert(message: message(for: reason), okAction: onRetry)
    }
}

// MARK: - Private implementation

private extension PolymarketBalanceBlockAlertBuilder {
    func message(for reason: PolymarketBalanceBlockViewModel.WithdrawUnavailability) -> String {
        switch reason {
        case .emptyBalance:
            Localization.predictionWithdrawEmptyBalance
        case .tooSmallBalance(let minimumFormatted):
            Localization.predictionWithdrawMinAmount(minimumFormatted)
        case .balanceUnavailable:
            Localization.predictionWithdrawBalanceUnavailable
        case .accountUnavailable:
            Localization.predictionAccountUnavailable
        }
    }
}
