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
    private let isFeatureAvailable: () -> Bool

    // [REDACTED_TODO_COMMENT]
    init(
        balanceConverter: BalanceConverter = BalanceConverter(),
        isFeatureAvailable: @escaping () -> Bool = { FeatureProvider.isAvailable(.highFeeWarning) }
    ) {
        self.balanceConverter = balanceConverter
        self.isFeatureAvailable = isFeatureAvailable
    }

    func shouldShowWarning(for tokenFee: TokenFee?) -> Bool {
        guard isFeatureAvailable(),
              let tokenFee,
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
