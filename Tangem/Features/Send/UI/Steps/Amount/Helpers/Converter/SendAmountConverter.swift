//
//  SendAmountConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountConverter {
    let converter = BalanceConverter()

    func convertToCrypto(_ fiatValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        guard let fiatValue,
              let currencyId = tokenItem.currencyId,
              let cryptoValue = converter.convertToCryptoFrom(fiatValue: fiatValue, currencyId: currencyId) else {
            return nil
        }

        let formatter = DecimalNumberFormatter(maximumFractionDigits: tokenItem.decimalCount)
        return formatter.format(value: cryptoValue)
    }

    func convertToFiat(_ cryptoValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        guard let cryptoValue,
              let currencyId = tokenItem.currencyId,
              let fiatValue = converter.convertToFiat(cryptoValue, currencyId: currencyId) else {
            return nil
        }

        let formatter = DecimalNumberFormatter(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)
        return formatter.format(value: fiatValue)
    }
}
