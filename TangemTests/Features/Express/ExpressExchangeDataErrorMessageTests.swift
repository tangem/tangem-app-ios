//
//  ExpressExchangeDataErrorMessageTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import TangemExpress
@testable import Tangem

@Suite("ExpressExchangeDataError — the alert message after a failed exchange-data request")
struct ExpressExchangeDataErrorMessageTests {
    @Test("A code with its own translation shows it")
    func translatedCode() {
        let error = makeError(underlying: ExpressAPIError(code: 2200, value: nil))

        #expect(error.localizedMessage == Localization.expressErrorSwapUnavailable(2200))
    }

    @Test("2264 names the provider that refused the transaction")
    func rejectedByProvider() {
        let error = makeError(underlying: ExpressAPIError(code: 2264, value: nil))

        #expect(error.localizedMessage == Localization.expressErrorTransactionCannotBeCreated("Changelly", 2264))
    }

    @Test("2240 asks to choose another provider, while the quote error card keeps its text")
    func pairUnavailable() {
        let apiError = ExpressAPIError(code: 2240, value: nil)
        let error = makeError(underlying: apiError)

        #expect(error.localizedMessage == Localization.warningExpressPairUnavailableMessageV2(2240))
        #expect(apiError.localizedMessage == Localization.warningExpressPairUnavailableMessage(2240))
    }

    @Test("A code without a translation shows the generic text with the real code")
    func untranslatedCode() {
        let error = makeError(underlying: ExpressAPIError(code: 2252, value: nil))

        #expect(error.localizedMessage == Localization.genericErrorCode(2252))
    }

    @Test("A minimum amount error with the amount shows it in the currency the amount was entered in")
    func minimumAmount() {
        let value = ExpressAPIError.Value(
            currentAllowance: nil,
            minAmount: "1500000",
            maxAmount: nil,
            decimals: 6,
            fromAmount: nil,
            fromAmountProvider: nil
        )
        let error = makeError(underlying: ExpressAPIError(code: 2250, value: value))
        let amount = BalanceFormatter().formatCryptoBalance(Decimal(string: "1.5"), currencyCode: "USDT")

        #expect(error.localizedMessage == Localization.warningExpressTooMinimalAmountTitle(amount))
    }

    @Test("A minimum amount error without the amount shows the generic text")
    func minimumAmountWithoutValue() {
        let error = makeError(underlying: ExpressAPIError(code: 2250, value: nil))

        #expect(error.localizedMessage == Localization.genericErrorCode(2250))
    }

    @Test("An error without a code keeps its own description")
    func errorWithoutCode() {
        let error = makeError(underlying: NetworkErrorStub())

        #expect(error.localizedMessage == NetworkErrorStub.message)
    }
}

private struct NetworkErrorStub: LocalizedError {
    static let message = "The request timed out."

    var errorDescription: String? { Self.message }
}

// MARK: - Helpers

private extension ExpressExchangeDataErrorMessageTests {
    func makeError(underlying: Error) -> ExpressExchangeDataError {
        ExpressExchangeDataError(
            provider: ExpressProvider(
                id: "changelly",
                name: "Changelly",
                type: .cex,
                exchangeOnlyWithinSingleAddress: false,
                imageURL: nil,
                termsOfUse: nil,
                privacyPolicy: nil,
                recommended: nil,
                slippage: nil,
                isCustomSlippageSupported: false
            ),
            currencySymbol: "USDT",
            underlying: underlying
        )
    }
}
