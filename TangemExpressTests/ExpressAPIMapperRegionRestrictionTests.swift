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

    @Test("A restricted exchange quote keeps the flag when the feature is on")
    func exchangeQuoteKeepsRestrictionWhenEnabled() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: true)
            .mapToExpressQuote(response: Self.makeExchangeQuoteResponse(isRestricted: true))

        #expect(quote.isRestricted)
    }

    /// The toggle gates the flag in the mapper so that with the feature off every consumer — including the
    /// best-provider selection inside the module — behaves exactly as it did before the flag existed.
    @Test("A restricted exchange quote drops the flag when the feature is off")
    func exchangeQuoteDropsRestrictionWhenDisabled() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: false)
            .mapToExpressQuote(response: Self.makeExchangeQuoteResponse(isRestricted: true))

        #expect(!quote.isRestricted)
    }

    @Test("An exchange quote without the field is not restricted")
    func exchangeQuoteWithoutFieldIsNotRestricted() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: true)
            .mapToExpressQuote(response: Self.makeExchangeQuoteResponse(isRestricted: nil))

        #expect(!quote.isRestricted)
    }

    // MARK: - Onramp

    @Test("A restricted onramp quote keeps the flag when the feature is on")
    func onrampQuoteKeepsRestrictionWhenEnabled() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: true)
            .mapToOnrampQuote(response: Self.makeOnrampQuoteResponse(isRestricted: true))

        #expect(quote.isRestricted)
    }

    @Test("A restricted onramp quote drops the flag when the feature is off")
    func onrampQuoteDropsRestrictionWhenDisabled() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: false)
            .mapToOnrampQuote(response: Self.makeOnrampQuoteResponse(isRestricted: true))

        #expect(!quote.isRestricted)
    }

    @Test("An onramp quote without the field is not restricted")
    func onrampQuoteWithoutFieldIsNotRestricted() throws {
        let quote = try makeMapper(isRegionRestrictionsEnabled: true)
            .mapToOnrampQuote(response: Self.makeOnrampQuoteResponse(isRestricted: nil))

        #expect(!quote.isRestricted)
    }
}

// MARK: - Helpers

private extension ExpressAPIMapperRegionRestrictionTests {
    func makeMapper(isRegionRestrictionsEnabled: Bool) -> ExpressAPIMapper {
        ExpressAPIMapper(
            exchangeDataDecoder: StubExchangeDataDecoder(),
            featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: isRegionRestrictionsEnabled)
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
            isRestricted: isRestricted
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
