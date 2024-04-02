//
//  FeeFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

protocol FeeFormatter {
    func formattedFeeComponents(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> FormattedFeeComponents
    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String
}

extension FeeFormatter {
    func formattedFeeComponents(fee: Decimal, tokenItem: TokenItem) -> FormattedFeeComponents {
        formattedFeeComponents(
            fee: fee,
            currencySymbol: tokenItem.currencySymbol,
            currencyId: tokenItem.currencyId,
            isFeeApproximate: tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType)
        )
    }

    func format(fee: Decimal, tokenItem: TokenItem) -> String {
        format(
            fee: fee,
            currencySymbol: tokenItem.currencySymbol,
            currencyId: tokenItem.currencyId,
            isFeeApproximate: tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType)
        )
    }
}
