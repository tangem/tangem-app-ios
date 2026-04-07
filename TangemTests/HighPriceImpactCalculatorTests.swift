//
//  HighPriceImpactCalculatorTests.swift
//  TangemTests
//
//  Created on 26.03.2026.
//

import Foundation
import Testing
import Combine
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("HighPriceImpactCalculator Tests", .serialized)
@MainActor
struct HighPriceImpactCalculatorTests {
    // MARK: - Test cases

    @Test("Loss below 10% returns negligible")
    func lossBelowThresholdReturnsNegligible() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 1000, destinationAmount: 950)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .negligible)
        #expect(result?.level.isNegligible == true)
        #expect(result?.isBlocked == false)
        #expect(result?.isHighLoss == false)
    }

    @Test("Loss between 10%-50% returns warningLoss")
    func lossBetween10And50ReturnsWarning() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 1000, destinationAmount: 800)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
        #expect(result?.isBlocked == false)
    }

    @Test("Loss above 50% with source <= $5000 returns highLossLowAmount")
    func highLossLowAmountReturnsWarningNotBlocked() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 1000, destinationAmount: 400)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
        #expect(result?.isBlocked == false)
    }

    @Test("Loss above 50% with source > $5000 returns highLossHighAmount and blocks")
    func highLossHighAmountReturnsBlocked() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 10000, destinationAmount: 4000)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .highLossHighAmount)
        #expect(result?.isBlocked == true)
    }

    @Test("Small trade <= $25 is exempt — returns negligible")
    func smallTradeIsExempt() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 20, destinationAmount: 5)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    @Test("No USD rate available - never blocks, still warns")
    func noUsdRateNeverBlocksStillWarns() async throws {
        let sourceCurrencyId = "source-token"
        let destCurrencyId = "dest-token"

        let previousCurrency = AppSettings.shared.selectedCurrencyCode
        AppSettings.shared.selectedCurrencyCode = "EUR"

        let quotes: Quotes = [
            sourceCurrencyId: TokenQuote(
                currencyId: sourceCurrencyId,
                price: 1.0,
                priceUsd: nil,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
            destCurrencyId: TokenQuote(
                currencyId: destCurrencyId,
                price: 1.0,
                priceUsd: nil,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
        ]

        let previousRepo = injectRepository(MockTokenQuotesRepository(quotes: quotes))
        defer {
            AppSettings.shared.selectedCurrencyCode = previousCurrency
            InjectedValues.setTokenQuotesRepository(previousRepo)
        }

        let input = HighPriceImpactCalculator.Input(
            provider: makeDexProvider(),
            sourceToken: makeTokenItem(currencyId: sourceCurrencyId),
            destinationToken: makeTokenItem(currencyId: destCurrencyId),
            sourceAmount: 10000,
            destinationAmount: 3000
        )

        let result = try await HighPriceImpactCalculator().calculate(input: input)

        // 70% loss, above 50% threshold, but no USD rate → cannot determine high amount → highLossLowAmount
        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
        #expect(result?.isBlocked == false)
    }

    @Test("Exact 50% boundary is highLossLowAmount (blockLimit is exclusive)")
    func exact50PercentBoundaryIsHighLoss() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 1000, destinationAmount: 500)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
    }

    @Test("Exact 10% boundary triggers warning")
    func exact10PercentBoundaryTriggersWarning() async throws {
        let (sut, input, teardown) = makeSUT(sourceAmount: 1000, destinationAmount: 900)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    // MARK: - $100K absolute loss threshold

    @Test("Loss below 10% but absolute USD diff > $100K triggers warningLoss")
    func lowPercentHighAbsoluteLossTriggersWarning() async throws {
        // 5% loss, source = $2,100,000, dest = $1,995,000 → diff = $105,000 > $100K
        let (sut, input, teardown) = makeSUT(sourceAmount: 2_100_000, destinationAmount: 1_995_000)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    @Test("Loss below 10% and absolute USD diff < $100K stays negligible")
    func lowPercentLowAbsoluteLossStaysNegligible() async throws {
        // ~8.6% loss, source = $1,100,000, dest = $1,005,000 → diff = $95,000 < $100K
        let (sut, input, teardown) = makeSUT(sourceAmount: 1_100_000, destinationAmount: 1_005_000)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    @Test("Loss below 10%, absolute USD diff exactly $100K triggers warningLoss (threshold is inclusive)")
    func exactThresholdBoundaryTriggersWarning() async throws {
        // ~4.76% loss, source = $2,100,000, dest = $2,000,000 → diff = exactly $100,000
        let (sut, input, teardown) = makeSUT(sourceAmount: 2_100_000, destinationAmount: 2_000_000)
        defer { teardown() }

        let result = try await sut.calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    @Test("Loss below 10%, absolute USD diff > $100K, but no priceUsd — stays negligible")
    func lowPercentHighAbsoluteLossNoPriceUsdStaysNegligible() async throws {
        let sourceCurrencyId = "source-token"
        let destCurrencyId = "dest-token"

        let previousCurrency = AppSettings.shared.selectedCurrencyCode
        AppSettings.shared.selectedCurrencyCode = "EUR"

        let quotes: Quotes = [
            sourceCurrencyId: TokenQuote(
                currencyId: sourceCurrencyId,
                price: 0.92,
                priceUsd: nil,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
            destCurrencyId: TokenQuote(
                currencyId: destCurrencyId,
                price: 0.92,
                priceUsd: nil,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
        ]

        let previousRepo = injectRepository(MockTokenQuotesRepository(quotes: quotes))
        defer {
            AppSettings.shared.selectedCurrencyCode = previousCurrency
            InjectedValues.setTokenQuotesRepository(previousRepo)
        }

        // 5% loss, source = 2,100,000 EUR, dest = 1,995,000 EUR → diff > $100K equivalent
        // but no priceUsd → can't determine USD amounts → stays negligible
        let input = HighPriceImpactCalculator.Input(
            provider: makeDexProvider(),
            sourceToken: makeTokenItem(currencyId: sourceCurrencyId),
            destinationToken: makeTokenItem(currencyId: destCurrencyId),
            sourceAmount: 2_100_000,
            destinationAmount: 1_995_000
        )

        let result = try await HighPriceImpactCalculator().calculate(input: input)

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    // MARK: - Non-USD currency tests

    @Test("Non-USD currency with priceUsd present still blocks on highLossHighAmount")
    func nonUsdCurrencyWithPriceUsdBlocksHighLoss() async throws {
        let sourceCurrencyId = "source-token"
        let destCurrencyId = "dest-token"

        let previousCurrency = AppSettings.shared.selectedCurrencyCode
        AppSettings.shared.selectedCurrencyCode = "EUR"

        let quotes: Quotes = [
            sourceCurrencyId: TokenQuote(
                currencyId: sourceCurrencyId,
                price: 0.92,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
            destCurrencyId: TokenQuote(
                currencyId: destCurrencyId,
                price: 0.92,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "EUR"
            ),
        ]

        let previousRepo = injectRepository(MockTokenQuotesRepository(quotes: quotes))
        defer {
            AppSettings.shared.selectedCurrencyCode = previousCurrency
            InjectedValues.setTokenQuotesRepository(previousRepo)
        }

        let input = HighPriceImpactCalculator.Input(
            provider: makeDexProvider(),
            sourceToken: makeTokenItem(currencyId: sourceCurrencyId),
            destinationToken: makeTokenItem(currencyId: destCurrencyId),
            sourceAmount: 10000,
            destinationAmount: 4000
        )

        let result = try await HighPriceImpactCalculator().calculate(input: input)

        // 60% loss, source = $10,000 USD via priceUsd path → highLossHighAmount
        #expect(result != nil)
        #expect(result?.level == .highLossHighAmount)
        #expect(result?.isBlocked == true)
    }

    @Test(
        "Consistent results across different app currencies",
        arguments: [
            ("USD", Decimal(1)),
            ("GBP", Decimal(sign: .plus, exponent: -2, significand: 79)),
            ("EUR", Decimal(sign: .plus, exponent: -2, significand: 92)),
            ("CAD", Decimal(sign: .plus, exponent: -2, significand: 136)),
            ("IDR", Decimal(15800)),
        ] as [(String, Decimal)]
    )
    func consistentResultsAcrossCurrencies(currencyCode: String, fiatPrice: Decimal) async throws {
        let sourceCurrencyId = "source-token"
        let destCurrencyId = "dest-token"

        let previousCurrency = AppSettings.shared.selectedCurrencyCode
        AppSettings.shared.selectedCurrencyCode = currencyCode

        let quotes: Quotes = [
            sourceCurrencyId: TokenQuote(
                currencyId: sourceCurrencyId,
                price: fiatPrice,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: currencyCode
            ),
            destCurrencyId: TokenQuote(
                currencyId: destCurrencyId,
                price: fiatPrice,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: currencyCode
            ),
        ]

        let previousRepo = injectRepository(MockTokenQuotesRepository(quotes: quotes))
        defer {
            AppSettings.shared.selectedCurrencyCode = previousCurrency
            InjectedValues.setTokenQuotesRepository(previousRepo)
        }

        let input = HighPriceImpactCalculator.Input(
            provider: makeDexProvider(),
            sourceToken: makeTokenItem(currencyId: sourceCurrencyId),
            destinationToken: makeTokenItem(currencyId: destCurrencyId),
            sourceAmount: 1000,
            destinationAmount: 700
        )

        let result = try await HighPriceImpactCalculator().calculate(input: input)

        // 30% loss → warningLoss regardless of currency
        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    // MARK: - Helpers

    /// Creates a SUT with price = 1.0 and priceUsd = 1.0 in USD so crypto amount == fiat == USD.
    /// Returns a teardown closure that restores DI and AppSettings.
    /// - Warning: Mutates `AppSettings.shared.selectedCurrencyCode` (UserDefaults-backed global state).
    ///   The suite is `.serialized` to prevent races, and `defer` restores the original value.
    private func makeSUT(
        sourceAmount: Decimal,
        destinationAmount: Decimal
    ) -> (HighPriceImpactCalculator, HighPriceImpactCalculator.Input, () -> Void) {
        let sourceCurrencyId = "source-token"
        let destCurrencyId = "dest-token"

        let previousCurrency = AppSettings.shared.selectedCurrencyCode
        AppSettings.shared.selectedCurrencyCode = "USD"

        let quotes: Quotes = [
            sourceCurrencyId: TokenQuote(
                currencyId: sourceCurrencyId,
                price: 1.0,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            ),
            destCurrencyId: TokenQuote(
                currencyId: destCurrencyId,
                price: 1.0,
                priceUsd: 1.0,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            ),
        ]

        let previousRepo = injectRepository(MockTokenQuotesRepository(quotes: quotes))

        let input = HighPriceImpactCalculator.Input(
            provider: makeDexProvider(),
            sourceToken: makeTokenItem(currencyId: sourceCurrencyId),
            destinationToken: makeTokenItem(currencyId: destCurrencyId),
            sourceAmount: sourceAmount,
            destinationAmount: destinationAmount
        )

        let teardown = {
            AppSettings.shared.selectedCurrencyCode = previousCurrency
            InjectedValues.setTokenQuotesRepository(previousRepo)
        }

        return (HighPriceImpactCalculator(), input, teardown)
    }

    /// Swaps the quotes repository with a mock and returns the previous one for teardown.
    /// - Note: Mutates global DI state. Tests in this suite run serialized to avoid races.
    private func injectRepository(
        _ mock: MockTokenQuotesRepository
    ) -> TokenQuotesRepository & TokenQuotesRepositoryUpdater {
        let previous = InjectedValues[\.quotesRepository]
        guard let previousComposite = previous as? TokenQuotesRepository & TokenQuotesRepositoryUpdater else {
            Issue.record("Expected quotesRepository to conform to both TokenQuotesRepository & TokenQuotesRepositoryUpdater")
            return mock // return mock as fallback so teardown doesn't crash
        }
        InjectedValues.setTokenQuotesRepository(mock)
        return previousComposite
    }

    private func makeTokenItem(currencyId: String) -> TokenItem {
        let token = Token(
            name: currencyId,
            symbol: currencyId.uppercased(),
            contractAddress: "0x\(currencyId)",
            decimalCount: 18,
            id: currencyId
        )
        let network = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
        return .token(token, network)
    }

    private func makeDexProvider() -> ExpressProvider {
        ExpressProvider(
            id: "test-dex",
            name: "Test DEX",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
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
            throw MockError.quoteNotFound
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

    private enum MockError: Error {
        case quoteNotFound
    }
}
