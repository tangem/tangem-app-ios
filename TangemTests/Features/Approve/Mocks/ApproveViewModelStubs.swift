//
//  ApproveViewModelStubs.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Foundation
@testable import Tangem

struct ApproveFeeFormatterStub: FeeFormatter {
    func formattedFeeComponents(
        fee: Decimal,
        currencySymbol: String,
        currencyId: String?,
        isFeeApproximate: Bool,
        formattingOptions: BalanceFormattingOptions
    ) -> FormattedFeeComponents {
        FormattedFeeComponents(cryptoFee: "", fiatFee: nil)
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String { "" }
}
