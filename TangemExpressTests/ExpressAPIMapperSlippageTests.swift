//
//  ExpressAPIMapperSlippageTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Express slippage mapping")
struct ExpressAPIMapperSlippageTests {
    private let mapper = ExpressAPIMapper(
        exchangeDataDecoder: StubExchangeDataDecoder(),
        featureFlags: ExpressFeatureFlags()
    )

    @Test(
        "A slippage fraction goes out in basis points",
        arguments: [
            (Decimal(string: "0.005")!, 50),
            (Decimal(string: "0.05")!, 500),
            (Decimal(string: "0.0001")!, 1),
            (Decimal(string: "0.00125")!, 13),
        ]
    )
    func fractionToBasisPoints(fraction: Decimal, expected: Int) {
        #expect(mapper.mapToSlippageBasisPoints(fraction: fraction) == expected)
    }

    @Test("The applied quote slippage comes back as a fraction")
    func quoteSlippageToFraction() throws {
        let quote = try mapper.mapToExpressQuote(response: Self.makeExchangeQuoteResponse(slippage: 50))

        #expect(quote.slippage == Decimal(string: "0.005"))
    }

    @Test("A quote without the applied slippage keeps it empty")
    func quoteWithoutSlippage() throws {
        let quote = try mapper.mapToExpressQuote(response: Self.makeExchangeQuoteResponse(slippage: nil))

        #expect(quote.slippage == nil)
    }

    @Test("A provider without the support flag doesn't accept a custom slippage")
    func providerSupportDefaultsToFalse() {
        #expect(!mapper.mapToExpressProvider(provider: Self.makeProviderResponse(isCustomSlippageSupported: nil)).isCustomSlippageSupported)
        #expect(mapper.mapToExpressProvider(provider: Self.makeProviderResponse(isCustomSlippageSupported: true)).isCustomSlippageSupported)
    }

    @Test("The provider default slippage comes as a percent and maps to a fraction")
    func providerDefaultSlippage() {
        let provider = mapper.mapToExpressProvider(provider: Self.makeProviderResponse(isCustomSlippageSupported: true))

        #expect(provider.slippage == Decimal(string: "0.005"))
    }
}

// MARK: - Helpers

private extension ExpressAPIMapperSlippageTests {
    static func makeExchangeQuoteResponse(slippage: Decimal?) -> ExpressDTO.Swap.ExchangeQuote.Response {
        .init(
            fromAmount: "1000000000000000000",
            fromDecimals: 18,
            toAmount: "2000000",
            toDecimals: 6,
            allowanceContract: nil,
            quoteId: "quote-id",
            expiredAt: nil,
            txType: nil,
            isRestricted: nil,
            slippage: slippage
        )
    }

    static func makeProviderResponse(isCustomSlippageSupported: Bool?) -> ExpressDTO.Swap.Providers.Response {
        .init(
            id: "1inch",
            name: "1inch",
            type: "dex",
            exchangeOnlyWithinSingleAddress: nil,
            imageLarge: nil,
            imageSmall: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: Decimal(string: "0.5"),
            isCustomSlippageSupported: isCustomSlippageSupported
        )
    }
}

private struct StubExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
