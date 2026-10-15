//
//  ExpressAPIMapperRegionRestrictionTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Express region restriction flag mapping")
struct ExpressAPIMapperRegionRestrictionTests {
    // MARK: - Swap

    @Test("A restricted exchange quote keeps the flag")
    func exchangeQuoteKeepsRestriction() throws {
        let quote = try makeMapper()
            .mapToExpressQuote(response: Self.makeExchangeQuoteResponse(isRestricted: true))

        #expect(quote.isRestricted)
    }

    @Test("An exchange quote without the field is not restricted")
    func exchangeQuoteWithoutFieldIsNotRestricted() throws {
        let quote = try makeMapper()
            .mapToExpressQuote(response: Self.makeExchangeQuoteResponse(isRestricted: nil))

        #expect(!quote.isRestricted)
    }

    // MARK: - Onramp

    @Test("A restricted onramp quote keeps the flag")
    func onrampQuoteKeepsRestriction() throws {
        let quote = try makeMapper()
            .mapToOnrampQuote(response: Self.makeOnrampQuoteResponse(isRestricted: true))

        #expect(quote.isRestricted)
    }

    @Test("An onramp quote without the field is not restricted")
    func onrampQuoteWithoutFieldIsNotRestricted() throws {
        let quote = try makeMapper()
            .mapToOnrampQuote(response: Self.makeOnrampQuoteResponse(isRestricted: nil))

        #expect(!quote.isRestricted)
    }
}

// MARK: - Helpers

private extension ExpressAPIMapperRegionRestrictionTests {
    func makeMapper() -> ExpressAPIMapper {
        ExpressAPIMapper(
            exchangeDataDecoder: StubExchangeDataDecoder(),
            featureFlags: ExpressFeatureFlags()
        )
    }

    static func makeExchangeQuoteResponse(isRestricted: Bool?) -> ExpressDTO.Swap.ExchangeQuote.Response {
        .init(
            fromAmount: "1000000000000000000",
            fromDecimals: 18,
            toAmount: "2000000",
            toDecimals: 6,
            allowanceContract: nil,
            quoteId: "quote-id",
            expiredAt: nil,
            txType: nil,
            isRestricted: isRestricted,
            slippage: nil
        )
    }

    static func makeOnrampQuoteResponse(isRestricted: Bool?) -> ExpressDTO.Onramp.Quote.Response {
        .init(
            fromCurrencyCode: "USD",
            toContractAddress: "0x0",
            toNetwork: "ethereum",
            paymentMethod: "card",
            countryCode: "US",
            fromAmount: "100",
            toAmount: "2000000",
            toDecimals: 6,
            providerId: "mercuryo",
            minFromAmount: nil,
            maxFromAmount: nil,
            minToAmount: nil,
            maxToAmount: nil,
            nativePaymentAvailable: nil,
            quoteId: "quote-id",
            isRestricted: isRestricted
        )
    }
}

private struct StubExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
