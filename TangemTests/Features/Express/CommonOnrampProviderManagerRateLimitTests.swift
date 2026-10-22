//
//  CommonOnrampProviderManagerRateLimitTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import TangemExpress

@Suite("CommonOnrampProviderManager rate limit handling")
struct CommonOnrampProviderManagerRateLimitTests {
    @Test("A rate-limited quote with nothing to restore marks the provider as failed")
    func rateLimitedFirstQuoteFails() async {
        let manager = makeManager(quoteResults: [.failure(rateLimitError)])

        await manager.update(amount: .amount(100))

        #expect(isFailed(manager.state))
    }

    @Test("A rate-limited refresh of the same amount keeps the loaded quote")
    func rateLimitedRefreshKeepsLoadedQuote() async {
        let manager = makeManager(quoteResults: [.success(quote), .failure(rateLimitError)])

        await manager.update(amount: .amount(100))
        await manager.update(amount: .same)

        #expect(loadedQuoteId(manager.state) == quote.quoteId)
    }

    @Test("A rate-limited quote for a new amount doesn't restore the quote of the previous amount")
    func rateLimitedNewAmountFails() async {
        let manager = makeManager(quoteResults: [.success(quote), .failure(rateLimitError)])

        await manager.update(amount: .amount(100))
        await manager.update(amount: .amount(200))

        #expect(isFailed(manager.state))
    }
}

// MARK: - Helpers

private extension CommonOnrampProviderManagerRateLimitTests {
    var quote: OnrampQuote {
        OnrampQuote(expectedAmount: 100, nativePaymentAvailable: false, quoteId: "quote-id", isRestricted: false)
    }

    var rateLimitError: MoyaError {
        .statusCode(Response(statusCode: 429, data: Data()))
    }

    func makeManager(quoteResults: [Result<OnrampQuote, Error>]) -> CommonOnrampProviderManager {
        let fiatCurrency = OnrampFiatCurrency(identity: OnrampIdentity(name: "Euro", code: "EUR", image: nil), precision: 2)
        let country = OnrampCountry(
            identity: OnrampIdentity(name: "Montenegro", code: "ME", image: nil),
            currency: fiatCurrency,
            onrampAvailable: true
        )
        let pairItem = OnrampPairRequestItem(
            fiatCurrency: fiatCurrency,
            country: country,
            destination: ExpressWalletCurrency(contractAddress: "coin", network: "ethereum", decimalCount: 18, symbol: "ETH"),
            address: "0x0"
        )
        let provider = OnrampTestFixtures.makeProvider(providerId: "simplex", paymentMethodId: "card")

        return CommonOnrampProviderManager(
            pairItem: pairItem,
            expressProvider: provider.provider,
            paymentMethod: provider.paymentMethod,
            apiProvider: QuoteStubExpressAPIProvider(quoteResults: quoteResults),
            analyticsLogger: NoopExpressAnalyticsLogger(),
            state: .idle
        )
    }

    func isFailed(_ state: OnrampProviderManagerState) -> Bool {
        if case .failed = state {
            return true
        }

        return false
    }

    func loadedQuoteId(_ state: OnrampProviderManagerState) -> String? {
        if case .loaded(let quote) = state {
            return quote.quoteId
        }

        return nil
    }
}

// MARK: - Stubs

private final class QuoteStubExpressAPIProvider: ExpressAPIProvider {
    private var quoteResults: [Result<OnrampQuote, Error>]

    init(quoteResults: [Result<OnrampQuote, Error>]) {
        self.quoteResults = quoteResults
    }

    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote {
        try quoteResults.removeFirst().get()
    }

    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { throw UnexpectedCall() }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { throw UnexpectedCall() }
    func providers(branches: [ExpressBranch]) async throws -> [ExpressProvider] { throw UnexpectedCall() }
    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote { throw UnexpectedCall() }
    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData { throw UnexpectedCall() }
    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction { throw UnexpectedCall() }
    func exchangeSent(result: ExpressTransactionSentResult) async throws { throw UnexpectedCall() }
    func onrampCurrencies() async throws -> [OnrampFiatCurrency] { throw UnexpectedCall() }
    func onrampCountries() async throws -> [OnrampCountry] { throw UnexpectedCall() }
    func onrampCountryByIP() async throws -> OnrampCountry { throw UnexpectedCall() }
    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] { throw UnexpectedCall() }
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair] { throw UnexpectedCall() }
    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData { throw UnexpectedCall() }
    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult { throw UnexpectedCall() }
    func onrampStatus(transactionId: String) async throws -> OnrampTransaction { throw UnexpectedCall() }
    func exchangeHistory(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage { throw UnexpectedCall() }
    func exchangeHistoryDelta(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage { throw UnexpectedCall() }
    func onrampHistory(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage { throw UnexpectedCall() }
    func onrampHistoryDelta(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage { throw UnexpectedCall() }

    private struct UnexpectedCall: Error {}
}

private struct NoopExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {}
    func logGasEstimationOverrideError(_ error: Error) {}
    func logAppError(_ error: Error, provider: ExpressProvider) {}
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}
}
