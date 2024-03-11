//
//  CommonFeeFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct CommonFeeFormatter {
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

// MARK: - FeeFormatter

extension CommonFeeFormatter: FeeFormatter {
    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String {
        let feeFormatted = balanceFormatter.formatCryptoBalance(fee, currencyCode: currencySymbol)

        guard let currencyId, let fiatFee = balanceConverter.convertToFiat(value: fee, from: currencyId) else {
            return feeFormatted
        }

        let fiatFeeFormatted = balanceFormatter.formatFiatBalance(fiatFee)
        let result = "\(feeFormatted) (\(fiatFeeFormatted))"
        if fee > 0, isFeeApproximate {
            return "< " + result
        } else {
            return result
        }
    }
}
