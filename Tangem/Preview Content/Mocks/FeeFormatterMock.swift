//
//  FeeFormatterMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct FeeFormatterMock: FeeFormatter {
    func formattedFeeParts(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> FormattedFeeParts {
        FormattedFeeParts(cryptoFee: "", fiatFee: nil)
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String { "" }
}
