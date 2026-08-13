//
//  HighNetworkFeeWarningCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct HighNetworkFeeWarningCalculator {
    private let balanceConverter: BalanceConverter

    init(balanceConverter: BalanceConverter = BalanceConverter()) {
        self.balanceConverter = balanceConverter
    }

    func shouldShowWarning(for tokenFee: TokenFee?) -> Bool {
        guard let tokenFee,
              case .success(let fee) = tokenFee.value,
              let currencyId = tokenFee.tokenItem.currencyId,
              let feeInUSD = balanceConverter.convertToUsd(fee.amount.value, currencyId: currencyId) else {
            return false
        }

        return feeInUSD > Constants.thresholdUSD
    }
}

private extension HighNetworkFeeWarningCalculator {
    enum Constants {
        static let thresholdUSD: Decimal = 10
    }
}
