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
    func formattedFeeComponents(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> FormattedFeeComponents {
        let cryptoFeeFormatted = balanceFormatter.formatCryptoBalance(fee, currencyCode: currencySymbol)
        let fiatFeeFormatted: String?

        if let currencyId, let fiatFee = balanceConverter.convertToFiat(value: fee, from: currencyId) {
            fiatFeeFormatted = balanceFormatter.formatFiatBalance(fiatFee)
        } else {
            fiatFeeFormatted = nil
        }

        let useApproximationSymbol = fee > 0 && isFeeApproximate

        return FormattedFeeComponents(
            cryptoFee: useApproximationSymbol ? ("< " + cryptoFeeFormatted) : cryptoFeeFormatted,
            fiatFee: fiatFeeFormatted
        )
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String {
        let formattedFee: FormattedFeeComponents = formattedFeeComponents(
            fee: fee,
            currencySymbol: currencySymbol,
            currencyId: currencyId,
            isFeeApproximate: isFeeApproximate
        )

        if let fiatFee = formattedFee.fiatFee {
            return "\(formattedFee.cryptoFee) (\(fiatFee))"
        } else {
            return formattedFee.cryptoFee
        }
    }
}
