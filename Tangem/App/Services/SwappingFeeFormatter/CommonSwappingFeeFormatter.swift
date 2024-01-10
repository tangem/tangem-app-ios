//
//  CommonSwappingFeeFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct CommonSwappingFeeFormatter {
    private let balanceFormatter: BalanceFormatter
    private let balanceConverter: BalanceConverter

    init(
        balanceFormatter: BalanceFormatter,
        balanceConverter: BalanceConverter
    ) {
        self.balanceFormatter = balanceFormatter
        self.balanceConverter = balanceConverter
    }
}

// MARK: - SwappingFeeFormatter

extension CommonSwappingFeeFormatter: SwappingFeeFormatter {
    func format(fee: Decimal, tokenItem: TokenItem) -> String {
        let currencySymbol = tokenItem.blockchain.currencySymbol
        let currencyId = tokenItem.blockchain.currencyId
        let feeFormatted = balanceFormatter.formatCryptoBalance(fee, currencyCode: currencySymbol)

        guard let fiatFee = balanceConverter.convertToFiat(value: fee, from: currencyId) else {
            return feeFormatted
        }

        let fiatFeeFormatted = balanceFormatter.formatFiatBalance(fiatFee)
        let result = "\(feeFormatted) (\(fiatFeeFormatted))"
        if fee > 0, tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType) {
            return "< " + result
        } else {
            return result
        }
    }
}
