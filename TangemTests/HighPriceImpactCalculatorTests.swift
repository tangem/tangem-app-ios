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
    private static let sourceCurrencyId = "source-token"
    private static let destinationCurrencyId = "dest-token"

    // MARK: - Test cases

    @Test("Loss below 10% returns negligible")
    func lossBelowThresholdReturnsNegligible() async throws {
        let result = try await calculate(sourceAmount: 1000, destinationAmount: 950)

        #expect(result != nil)
        #expect(result?.level == .negligible)
        #expect(result?.level.isNegligible == true)
        #expect(result?.isBlocked == false)
        #expect(result?.isHighLoss == false)
    }

    @Test("Loss between 10%-50% returns warningLoss")
    func lossBetween10And50ReturnsWarning() async throws {
        let result = try await calculate(sourceAmount: 1000, destinationAmount: 800)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
        #expect(result?.isBlocked == false)
    }

    @Test("Loss above 50% with source <= $5000 returns highLossLowAmount")
    func highLossLowAmountReturnsWarningNotBlocked() async throws {
        let result = try await calculate(sourceAmount: 1000, destinationAmount: 400)

        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
        #expect(result?.isBlocked == false)
    }

    @Test("Loss above 50% with source > $5000 returns highLossHighAmount and blocks")
    func highLossHighAmountReturnsBlocked() async throws {
        let result = try await calculate(sourceAmount: 10000, destinationAmount: 4000)

        #expect(result != nil)
        #expect(result?.level == .highLossHighAmount)
        #expect(result?.isBlocked == true)
    }

    @Test("Small trade <= $25 is exempt — returns negligible")
    func smallTradeIsExempt() async throws {
        let result = try await calculate(sourceAmount: 20, destinationAmount: 5)

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    @Test("No USD rate available - never blocks, still warns")
    func noUsdRateNeverBlocksStillWarns() async throws {
        // 70% loss, above 50% threshold, but no USD rate → cannot determine high amount → highLossLowAmount
        let result = try await calculate(
            sourceAmount: 10000,
            destinationAmount: 3000,
            currencyCode: "EUR",
            price: 1.0,
            priceUsd: nil
        )

        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
        #expect(result?.isBlocked == false)
    }

    @Test("Exact 50% boundary is highLossLowAmount (blockLimit is exclusive)")
    func exact50PercentBoundaryIsHighLoss() async throws {
        let result = try await calculate(sourceAmount: 1000, destinationAmount: 500)

        #expect(result != nil)
        #expect(result?.level == .highLossLowAmount)
    }

    @Test("Exact 10% boundary triggers warning")
    func exact10PercentBoundaryTriggersWarning() async throws {
        let result = try await calculate(sourceAmount: 1000, destinationAmount: 900)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    // MARK: - $100K absolute loss threshold

    @Test("Loss below 10% but absolute USD diff > $100K triggers warningLoss")
    func lowPercentHighAbsoluteLossTriggersWarning() async throws {
        // 5% loss, source = $2,100,000, dest = $1,995,000 → diff = $105,000 > $100K
        let result = try await calculate(sourceAmount: 2_100_000, destinationAmount: 1_995_000)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    @Test("Loss below 10% and absolute USD diff < $100K stays negligible")
    func lowPercentLowAbsoluteLossStaysNegligible() async throws {
        // ~8.6% loss, source = $1,100,000, dest = $1,005,000 → diff = $95,000 < $100K
        let result = try await calculate(sourceAmount: 1_100_000, destinationAmount: 1_005_000)

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    @Test("Loss below 10%, absolute USD diff exactly $100K triggers warningLoss (threshold is inclusive)")
    func exactThresholdBoundaryTriggersWarning() async throws {
        // ~4.76% loss, source = $2,100,000, dest = $2,000,000 → diff = exactly $100,000
        let result = try await calculate(sourceAmount: 2_100_000, destinationAmount: 2_000_000)

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    @Test("Loss below 10%, absolute USD diff > $100K, but no priceUsd — stays negligible")
    func lowPercentHighAbsoluteLossNoPriceUsdStaysNegligible() async throws {
        // 5% loss, source = 2,100,000 EUR, dest = 1,995,000 EUR → diff > $100K equivalent
        // but no priceUsd → can't determine USD amounts → stays negligible
        let result = try await calculate(
            sourceAmount: 2_100_000,
            destinationAmount: 1_995_000,
            currencyCode: "EUR",
            price: 0.92,
            priceUsd: nil
        )

        #expect(result != nil)
        #expect(result?.level == .negligible)
    }

    // MARK: - Non-USD currency tests

    @Test("Non-USD currency with priceUsd present still blocks on highLossHighAmount")
    func nonUsdCurrencyWithPriceUsdBlocksHighLoss() async throws {
        // 60% loss, source = $10,000 USD via priceUsd path → highLossHighAmount
        let result = try await calculate(
            sourceAmount: 10000,
            destinationAmount: 4000,
            currencyCode: "EUR",
            price: 0.92,
            priceUsd: 1.0
        )

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
        // 30% loss → warningLoss regardless of currency
        let result = try await calculate(
            sourceAmount: 1000,
            destinationAmount: 700,
            currencyCode: currencyCode,
            price: fiatPrice,
            priceUsd: 1.0
        )

        #expect(result != nil)
        #expect(result?.level == .warningLoss)
    }

    // MARK: - Helpers

    /// Runs the calculator with the quotes repository and app currency swapped for the duration of
    /// the call. The whole swap-calculate-restore sequence holds `InjectedDependenciesIsolation`,
    /// so parallel suites touching the same globals cannot observe the mock.
    private func calculate(
        sourceAmount: Decimal,
        destinationAmount: Decimal,
        currencyCode: String = "USD",
        price: Decimal = 1.0,
        priceUsd: Decimal? = 1.0
    ) async throws -> HighPriceImpactCalculator.Result? {
        try await InjectedDependenciesIsolation.shared.run {
            let previousCurrency = AppSettings.shared.selectedCurrencyCode
            let previousRepo = injectRepository(MockTokenQuotesRepository(
                quotes: makeQuotes(price: price, priceUsd: priceUsd, currencyCode: currencyCode)
            ))
            AppSettings.shared.selectedCurrencyCode = currencyCode
            defer {
                AppSettings.shared.selectedCurrencyCode = previousCurrency
                InjectedValues.setTokenQuotesRepository(previousRepo)
            }

            let input = HighPriceImpactCalculator.Input(
                provider: makeDexProvider(),
                sourceToken: makeTokenItem(currencyId: Self.sourceCurrencyId),
                destinationToken: makeTokenItem(currencyId: Self.destinationCurrencyId),
                sourceAmount: sourceAmount,
                destinationAmount: destinationAmount
            )

            return try await HighPriceImpactCalculator().calculate(input: input)
        }
    }

    private func makeQuotes(price: Decimal, priceUsd: Decimal?, currencyCode: String) -> Quotes {
        [Self.sourceCurrencyId, Self.destinationCurrencyId].reduce(into: Quotes()) { quotes, currencyId in
            quotes[currencyId] = TokenQuote(
                currencyId: currencyId,
                price: price,
                priceUsd: priceUsd,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: currencyCode
            )
        }
    }

    /// Swaps the quotes repository with a mock and returns the previous one for teardown.
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
