//
//  SupportedProvidersFilterTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("SupportedProvidersFilter — provider support predicate")
struct SupportedProvidersFilterTests {
    @Test(
        "Filter by types accepts only listed provider types",
        arguments: [
            (ExpressProviderType.cex, true),
            (.dex, true),
            (.dexBridge, true),
            (.onramp, false),
            (.unknown, false),
        ]
    )
    func swapFilterAcceptsOnlySwapTypes(type: ExpressProviderType, expected: Bool) {
        let provider = makeProvider(type: type, exchangeOnlyWithinSingleAddress: false)

        #expect(SupportedProvidersFilter.swap.isSupported(provider: provider) == expected)
    }

    @Test(
        "Different-address filter rejects providers exchanging only within a single address",
        arguments: [
            (false, true),
            (true, false),
        ]
    )
    func differentAddressFilterChecksSingleAddressFlag(exchangeOnlyWithinSingleAddress: Bool, expected: Bool) {
        let provider = makeProvider(type: .dex, exchangeOnlyWithinSingleAddress: exchangeOnlyWithinSingleAddress)

        #expect(SupportedProvidersFilter.byDifferentAddressExchangeSupport.isSupported(provider: provider) == expected)
    }
}

// MARK: - Helpers

private extension SupportedProvidersFilterTests {
    func makeProvider(type: ExpressProviderType, exchangeOnlyWithinSingleAddress: Bool) -> ExpressProvider {
        ExpressProvider(
            id: "provider",
            name: "Provider",
            type: type,
            exchangeOnlyWithinSingleAddress: exchangeOnlyWithinSingleAddress,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }
}
