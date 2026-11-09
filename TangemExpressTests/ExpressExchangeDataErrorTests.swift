//
//  ExpressExchangeDataErrorTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("ExpressExchangeDataError — which provider an exchange-data error hides")
struct ExpressExchangeDataErrorTests {
    @Test("ChangeHero is hidden only by 2264", arguments: [
        (2264, true),
        (2200, false),
        (2250, false),
    ])
    func changeHero(code: Int, hides: Bool) {
        let error = makeError(providerId: "changehero", underlying: ExpressAPIError(code: code, value: nil))

        #expect(error.hidesProvider == hides)
    }

    @Test("ChangeHero is not hidden by an error without a code")
    func changeHeroWithoutCode() {
        let error = makeError(providerId: "changehero", underlying: URLError(.timedOut))

        #expect(!error.hidesProvider)
    }

    @Test("Changelly is hidden by any code except the ones the user fixes", arguments: [
        (2250, false),
        (2251, false),
        (2252, false),
        (2270, false),
        (2280, false),
        (2310, false),
        (2320, false),
        (2200, true),
        (2240, true),
        (2264, true),
    ])
    func changelly(code: Int, hides: Bool) {
        let error = makeError(providerId: "changelly", underlying: ExpressAPIError(code: code, value: nil))

        #expect(error.hidesProvider == hides)
    }

    @Test("Changelly is hidden by an error without a code")
    func changellyWithoutCode() {
        #expect(makeError(providerId: "changelly", underlying: URLError(.timedOut)).hidesProvider)
        #expect(makeError(providerId: "changelly", underlying: ExpressAPIError(code: nil, value: nil)).hidesProvider)
    }

    @Test("Other providers are never hidden")
    func otherProvider() {
        #expect(!makeError(providerId: "swapkit", underlying: ExpressAPIError(code: 2264, value: nil)).hidesProvider)
        #expect(!makeError(providerId: "changenow", underlying: URLError(.timedOut)).hidesProvider)
    }
}

// MARK: - Helpers

private extension ExpressExchangeDataErrorTests {
    func makeError(providerId: ExpressProvider.Id, underlying: Error) -> ExpressExchangeDataError {
        ExpressExchangeDataError(
            provider: ExpressProvider(
                id: providerId,
                name: providerId,
                type: .cex,
                exchangeOnlyWithinSingleAddress: false,
                imageURL: nil,
                termsOfUse: nil,
                privacyPolicy: nil,
                recommended: nil,
                slippage: nil,
                isCustomSlippageSupported: false
            ),
            currencySymbol: "BTC",
            underlying: underlying
        )
    }
}
