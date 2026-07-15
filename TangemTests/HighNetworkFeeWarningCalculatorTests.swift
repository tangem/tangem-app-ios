//
//  HighNetworkFeeWarningCalculatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("HighNetworkFeeWarningCalculator Tests", .serialized)
@MainActor
struct HighNetworkFeeWarningCalculatorTests {
    private let currencyId = "test-token"

    @Test("Nil token fee does not show warning")
    func nilTokenFeeDoesNotShowWarning() {
        let (sut, teardown) = makeSUT()
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: nil) == false)
    }

    @Test("Feature disabled does not show warning")
    func featureDisabledDoesNotShowWarning() {
        let tokenFee = makeTokenFee(value: 11)
        let (sut, teardown) = makeSUT(isFeatureAvailable: false)
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: tokenFee) == false)
    }

    @Test(
        "Fee threshold is exclusive",
        arguments: [
            (Decimal(9), false),
            (Decimal(10), false),
            (Decimal(11), true),
        ] as [(Decimal, Bool)]
    )
    func feeThresholdIsExclusive(feeValue: Decimal, shouldShowWarning: Bool) {
        let tokenFee = makeTokenFee(value: feeValue)
        let (sut, teardown) = makeSUT()
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: tokenFee) == shouldShowWarning)
    }

    @Test("Token quote priceUsd is used for threshold")
    func tokenQuotePriceUsdIsUsedForThreshold() {
        let tokenFee = makeTokenFee(value: 4)
        let (sut, teardown) = makeSUT(priceUsd: 3)
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: tokenFee) == true)
    }

    @Test("Missing USD quote does not show warning")
    func missingUsdQuoteDoesNotShowWarning() {
        let tokenFee = makeTokenFee(value: 11)
        let (sut, teardown) = makeSUT(priceUsd: nil)
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: tokenFee) == false)
    }

    @Test("Non-success fee result does not show warning")
    func nonSuccessFeeResultDoesNotShowWarning() {
        let (sut, teardown) = makeSUT()
        defer { teardown() }

        #expect(sut.shouldShowWarning(for: makeTokenFee(value: .loading)) == false)
        #expect(sut.shouldShowWarning(for: makeTokenFee(value: .failure(TestError.feeFailed))) == false)
    }
}

// MARK: - Helpers

private extension HighNetworkFeeWarningCalculatorTests {
    func makeSUT(
        priceUsd: Decimal? = 1,
        isFeatureAvailable: Bool = true
    ) -> (HighNetworkFeeWarningCalculator, () -> Void) {
        let previousRepository = injectRepository(MockTokenQuotesRepository(quotes: makeQuotes(priceUsd: priceUsd)))
        let sut = HighNetworkFeeWarningCalculator(isFeatureAvailable: { isFeatureAvailable })

        let teardown = {
            InjectedValues.setTokenQuotesRepository(previousRepository)
        }

        return (sut, teardown)
    }

    func injectRepository(
        _ mock: MockTokenQuotesRepository
    ) -> TokenQuotesRepository & TokenQuotesRepositoryUpdater {
        let previousRepository = InjectedValues[\.quotesRepository]
        guard let previousComposite = previousRepository as? TokenQuotesRepository & TokenQuotesRepositoryUpdater else {
            Issue.record("Expected quotesRepository to conform to both TokenQuotesRepository & TokenQuotesRepositoryUpdater")
            return mock
        }

        InjectedValues.setTokenQuotesRepository(mock)
        return previousComposite
    }

    func makeQuotes(priceUsd: Decimal?) -> Quotes {
        [
            currencyId: TokenQuote(
                currencyId: currencyId,
                price: 1,
                priceUsd: priceUsd,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            ),
        ]
    }

    func makeTokenFee(value: Decimal) -> TokenFee {
        makeTokenFee(value: .success(makeFee(value)))
    }

    func makeTokenFee(value: LoadingResult<BSDKFee, any Error>) -> TokenFee {
        TokenFee(
            option: .market,
            tokenItem: makeTokenItem(),
            value: value
        )
    }

    func makeFee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: value))
    }

    func makeTokenItem() -> TokenItem {
        let token = Token(
            name: "Test Token",
            symbol: "TEST",
            contractAddress: "0xTEST",
            decimalCount: 18,
            id: currencyId
        )

        return .token(token, .init(.ethereum(testnet: false), derivationPath: nil))
    }
}

// MARK: - Mock

private final class MockTokenQuotesRepository: TokenQuotesRepository, TokenQuotesRepositoryUpdater {
    var quotes: Quotes
    var quotesPublisher: AnyPublisher<Quotes, Never> {
        Just(quotes).eraseToAnyPublisher()
    }

    init(quotes: Quotes) {
        self.quotes = quotes
    }

    func quote(for currencyId: String) async throws -> TokenQuote {
        guard let quote = quotes[currencyId] else {
            throw TestError.quoteNotFound
        }

        return quote
    }

    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Quotes, Never> {
        Just(quotes).eraseToAnyPublisher()
    }

    func fetchFreshQuoteFor(currencyId: String, shouldUpdateCache: Bool) async throws -> TokenQuote {
        try await quote(for: currencyId)
    }

    func saveQuotes(_ quotes: [TokenQuote]) {
        for quote in quotes {
            self.quotes[quote.currencyId] = quote
        }
    }
}

private enum TestError: Error {
    case feeFailed
    case quoteNotFound
}
