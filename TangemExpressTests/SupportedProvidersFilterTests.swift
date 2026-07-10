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

    @Test(
        "Yield providers filter accepts CEX and allow-listed DEX providers",
        arguments: [
            ("cex-provider", ExpressProviderType.cex, true),
            ("1inch", .dex, true),
            ("lifi", .dexBridge, true),
            ("unsupported-dex", .dex, false),
            ("unsupported-bridge", .dexBridge, false),
            ("onramp-provider", .onramp, false),
            ("unknown-provider", .unknown, false),
        ]
    )
    func yieldProvidersFilterAcceptsCEXAndAllowedDEX(id: ExpressProvider.Id, type: ExpressProviderType, expected: Bool) {
        let provider = makeProvider(id: id, type: type, exchangeOnlyWithinSingleAddress: false)

        let filter = SupportedProvidersFilter.yieldProviders(YieldProvidersFilter())

        #expect(filter.isSupported(provider: provider) == expected)
    }
}

// MARK: - Helpers

private extension SupportedProvidersFilterTests {
    func makeProvider(
        id: ExpressProvider.Id = "provider",
        type: ExpressProviderType,
        exchangeOnlyWithinSingleAddress: Bool
    ) -> ExpressProvider {
        ExpressProvider(
            id: id,
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
