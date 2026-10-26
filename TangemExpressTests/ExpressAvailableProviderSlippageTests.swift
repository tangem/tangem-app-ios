//
//  ExpressAvailableProviderSlippageTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import TangemExpress

@Suite("ExpressAvailableProvider — custom slippage")
struct ExpressAvailableProviderSlippageTests {
    @Test("A custom slippage reaches only a provider that supports it", arguments: [true, false])
    func customSlippageIsGatedByProviderSupport(isCustomSlippageSupported: Bool) async {
        let manager = ExpressProviderManagerSpy()
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: isCustomSlippageSupported), manager: manager)

        await sut.update(request: ExpressAvailableProviderUpdatingRequest(
            amountType: .from(1),
            approvePolicy: .specified,
            slippage: Decimal(string: "0.01"),
            quotesLoadingPerformanceTracker: nil
        ))

        #expect(manager.requests.map(\.slippage) == [isCustomSlippageSupported ? Decimal(string: "0.01") : nil])
    }

    @Test("The default slippage comes from the quote requested without a custom slippage")
    func defaultSlippageComesFromQuote() async {
        let manager = ExpressProviderManagerSpy(quoteSlippage: { _ in Self.quoteSlippage })
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: true, slippage: Self.providerSlippage), manager: manager)

        await sut.update(request: makeRequest(slippage: nil))

        #expect(sut.defaultSlippage == Self.quoteSlippage)
    }

    @Test("A quote requested with a custom slippage keeps the default slippage")
    func customSlippageQuoteKeepsDefault() async {
        let manager = ExpressProviderManagerSpy(quoteSlippage: { $0 ?? Self.quoteSlippage })
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: true, slippage: Self.providerSlippage), manager: manager)

        await sut.update(request: makeRequest(slippage: nil))
        await sut.update(request: makeRequest(slippage: Self.customSlippage))

        #expect(sut.defaultSlippage == Self.quoteSlippage)
    }

    @Test("Without a quote slippage the default slippage falls back to the provider one")
    func defaultSlippageFallsBackToProvider() async {
        let manager = ExpressProviderManagerSpy(quoteSlippage: { _ in nil })
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: true, slippage: Self.providerSlippage), manager: manager)

        await sut.update(request: makeRequest(slippage: nil))

        #expect(sut.defaultSlippage == Self.providerSlippage)
    }

    @Test("A failed quote keeps the default slippage from the last quote")
    func failedQuoteKeepsDefault() async {
        let manager = ExpressProviderManagerSpy(quoteSlippage: { _ in Self.quoteSlippage })
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: true, slippage: Self.providerSlippage), manager: manager)

        await sut.update(request: makeRequest(slippage: nil))
        manager.failQuotes()
        await sut.update(request: makeRequest(slippage: nil))

        #expect(sut.defaultSlippage == Self.quoteSlippage)
    }

    @Test("A reset drops the quote slippage")
    func resetDropsQuoteSlippage() async {
        let manager = ExpressProviderManagerSpy(quoteSlippage: { _ in Self.quoteSlippage })
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: true, slippage: Self.providerSlippage), manager: manager)

        await sut.update(request: makeRequest(slippage: nil))
        sut.reset()

        #expect(sut.defaultSlippage == Self.providerSlippage)
    }
}

// MARK: - Helpers

private extension ExpressAvailableProviderSlippageTests {
    static let providerSlippage = Decimal(string: "0.035")!
    static let quoteSlippage = Decimal(string: "0.003")!
    static let customSlippage = Decimal(string: "0.01")!

    func makeRequest(slippage: Decimal?) -> ExpressAvailableProviderUpdatingRequest {
        ExpressAvailableProviderUpdatingRequest(
            amountType: .from(100),
            approvePolicy: .specified,
            slippage: slippage,
            quotesLoadingPerformanceTracker: nil
        )
    }

    func makeContext(isCustomSlippageSupported: Bool, slippage: Decimal? = nil) -> ExpressProviderFlowContext {
        let source = SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: "0xOwner", allowanceProvider: nil)
        let provider = ExpressProvider(
            id: "test-provider",
            name: "Test",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: slippage,
            isCustomSlippageSupported: isCustomSlippageSupported
        )

        return ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: source, destination: DestinationWalletStub()),
            rateType: .float,
            expressFeeProvider: FeeProviderStub(
                combinedResult: .failure(StubError.estimateFailed),
                approveFee: Fee(Amount(with: .ethereum(testnet: false), value: 0))
            ),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags()
        )
    }
}

// MARK: - Doubles

final class ExpressProviderManagerSpy: ExpressProviderManager {
    var requests: [ExpressManagerSwappingPairRequest] { _requests.withLock { $0 } }

    private let _requests = OSAllocatedUnfairLock(initialState: [ExpressManagerSwappingPairRequest]())
    private let _quotedSlippage = OSAllocatedUnfairLock<Decimal??>(initialState: nil)
    private let _isQuoteFailing = OSAllocatedUnfairLock(initialState: false)
    private let quoteSlippage: (@Sendable (_ requestSlippage: Decimal?) -> Decimal?)?

    init(quoteSlippage: (@Sendable (_ requestSlippage: Decimal?) -> Decimal?)? = nil) {
        self.quoteSlippage = quoteSlippage
    }

    func getState() -> ExpressProviderManagerState {
        guard let slippage = _quotedSlippage.withLock({ $0 }) else {
            return .idle
        }

        let quote = ExpressQuote(
            fromAmount: 100,
            expectAmount: 100,
            allowanceContract: nil,
            quoteId: nil,
            txType: nil,
            isRestricted: false,
            slippage: slippage
        )
        return .error(StubError.estimateFailed, quote: quote)
    }

    func failQuotes() {
        _isQuoteFailing.withLock { $0 = true }
    }

    func reset() {
        _quotedSlippage.withLock { $0 = nil }
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        _requests.withLock { $0.append(request) }

        if _isQuoteFailing.withLock({ $0 }) {
            _quotedSlippage.withLock { $0 = nil }
        } else if let quoteSlippage {
            let slippage = quoteSlippage(request.slippage)
            _quotedSlippage.withLock { $0 = .some(slippage) }
        }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        throw StubError.estimateFailed
    }
}
