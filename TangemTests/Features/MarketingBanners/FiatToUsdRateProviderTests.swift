//
//  FiatToUsdRateProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("FiatToUsdRateProvider", .tags(.marketingBanners))
struct FiatToUsdRateProviderTests {
    @Test("USD needs no request and converts one to one", arguments: ["USD", "usd"])
    func usdIsIdentity(currencyCode: String) async throws {
        let apiSpy = QuotesApiSpy(price: 1, priceUsd: 1)

        try await withInjectedTangemApiService(apiSpy.fake) {
            let rate = try await FiatToUsdRateProvider().rate(for: currencyCode)

            #expect(rate == 1)
            #expect(apiSpy.requests.isEmpty)
        }
    }

    @Test("Rate is the reference coin USD price over its price in the requested currency")
    func rateFromReferenceCoinQuote() async throws {
        let apiSpy = QuotesApiSpy(price: Decimal(string: "80000")!, priceUsd: Decimal(string: "100000")!)

        try await withInjectedTangemApiService(apiSpy.fake) {
            let rate = try await FiatToUsdRateProvider(referenceCoinId: "bitcoin").rate(for: "eur")

            #expect(rate == Decimal(string: "1.25")!)

            let request = try #require(apiSpy.requests.first)
            #expect(request.coinIds == ["bitcoin"])
            #expect(request.currencyId == "EUR")
            #expect(request.fields == [.price, .priceUsd])
        }
    }

    @Test("Rate is fetched once per currency and then served from the cache")
    func rateIsCachedPerCurrency() async throws {
        let apiSpy = QuotesApiSpy(price: Decimal(string: "80000")!, priceUsd: Decimal(string: "100000")!)

        try await withInjectedTangemApiService(apiSpy.fake) {
            let sut = FiatToUsdRateProvider()

            _ = try await sut.rate(for: "EUR")
            _ = try await sut.rate(for: "EUR")
            _ = try await sut.rate(for: "GBP")

            #expect(apiSpy.requests.map(\.currencyId) == ["EUR", "GBP"])
        }
    }

    @Test("An unusable answer is retried on the next lookup, so the rate recovers once the backend does")
    func unusableAnswerIsRetried() async throws {
        let apiSpy = QuotesApiSpy(price: Decimal(string: "80000")!, priceUsd: Decimal(string: "100000")!, unusableAnswers: 1)

        try await withInjectedTangemApiService(apiSpy.fake) {
            let sut = FiatToUsdRateProvider()

            let unusable = try? await sut.rate(for: "EUR")
            let recovered = try await sut.rate(for: "eur")

            #expect(unusable == nil)
            #expect(recovered == Decimal(string: "1.25")!)
            #expect(apiSpy.requests.count == 2)
        }
    }

    @Test("A failed request is retried on the next lookup, so the rate recovers with the connection")
    func failedRequestIsRetried() async throws {
        let apiSpy = QuotesApiSpy(price: Decimal(string: "80000")!, priceUsd: Decimal(string: "100000")!, failingRequests: 1)

        try await withInjectedTangemApiService(apiSpy.fake) {
            let sut = FiatToUsdRateProvider()

            let failed = try? await sut.rate(for: "EUR")
            let recovered = try await sut.rate(for: "EUR")

            #expect(failed == nil)
            #expect(recovered == Decimal(string: "1.25")!)
            #expect(apiSpy.requests.count == 2)
        }
    }

    @Test("A currency at dollar parity converts one to one")
    func dollarParityCurrencyConvertsOneToOne() async throws {
        let apiSpy = QuotesApiSpy(price: Decimal(string: "100000")!, priceUsd: Decimal(string: "100000")!)

        let rate = try await withInjectedTangemApiService(apiSpy.fake) {
            try await FiatToUsdRateProvider().rate(for: "BSD")
        }

        #expect(rate == 1)
    }

    @Test("Missing USD price or zero price fails instead of producing a rate", arguments: [
        (Decimal(string: "80000")!, Decimal?.none),
        (Decimal.zero, Decimal?.some(Decimal(string: "100000")!)),
    ])
    func unusableQuoteThrows(price: Decimal, priceUsd: Decimal?) async {
        let apiSpy = QuotesApiSpy(price: price, priceUsd: priceUsd)

        await withInjectedTangemApiService(apiSpy.fake) {
            _ = await #expect(throws: FiatToUsdRateProviderError.self) {
                try await FiatToUsdRateProvider().rate(for: "EUR")
            }
        }
    }
}

private final class QuotesApiSpy {
    let fake = FakeTangemApiService()

    private let state = OSAllocatedUnfairLock(initialState: [QuotesDTO.Request]())

    init(price: Decimal, priceUsd: Decimal?, failingRequests: Int = 0, unusableAnswers: Int = 0) {
        fake.loadQuotesHandler = { [state] request in
            let requestNumber = state.withLock { requests in
                requests.append(request)
                return requests.count
            }

            if requestNumber <= failingRequests {
                throw URLError(.notConnectedToInternet)
            }

            let isUnusable = requestNumber <= failingRequests + unusableAnswers

            return request.coinIds.map { coinId in
                Quote(
                    id: coinId,
                    price: isUnusable ? 0 : price,
                    priceUsd: isUnusable ? nil : priceUsd,
                    priceChange: nil,
                    priceChange7d: nil,
                    priceChange30d: nil,
                    prices24h: nil
                )
            }
        }
    }

    var requests: [QuotesDTO.Request] {
        state.withLock { $0 }
    }
}
