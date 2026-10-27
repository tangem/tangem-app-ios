//
//  CommonExpressManagerBestProviderTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("CommonExpressManager — default provider selection")
struct CommonExpressManagerBestProviderTests {
    @Test("Preselects the best rate even when it is a CEX and a ready DEX is available")
    func preselectsBestRateCEXOverReadyDEX() async throws {
        let sut = makeSUT()

        _ = try await sut.update(pair: makePair())
        let state = try await sut.update(amountType: .from(1))

        guard case .swap(.some(let selected), let providers) = state else {
            Issue.record("Expected a selected swap provider, got \(state)")
            return
        }

        let dex = providers.availableProviders(rate: .float).first { $0.provider.id == "dex" }
        #expect(selected.provider.id == "cex")
        #expect(selected.isBest)
        #expect(dex?.isBestDEX == true)
    }

    @Test("Preselects the ready DEX over a better CEX when DEX providers are preferred")
    func preselectsReadyDEXWhenPreferred() async throws {
        let sut = makeSUT()
        await sut.update(prefersDEX: true)

        _ = try await sut.update(pair: makePair())
        let state = try await sut.update(amountType: .from(1))

        guard case .swap(.some(let selected), _) = state else {
            Issue.record("Expected a selected swap provider, got \(state)")
            return
        }

        #expect(selected.provider.id == "dex")
    }

    @Test("Turning the DEX preference on replaces a selected CEX with the ready DEX, even on an autoupdate")
    func enablingPreferenceReselectsDEXOnAutoupdate() async throws {
        let sut = makeSUT()

        _ = try await sut.update(pair: makePair())
        let loaded = try await sut.update(amountType: .from(1))

        guard case .swap(.some(let initial), _) = loaded, initial.provider.id == "cex" else {
            Issue.record("Expected the CEX to be selected first, got \(loaded)")
            return
        }

        await sut.update(prefersDEX: true)
        let state = await sut.update(type: .autoupdate)

        guard case .swap(.some(let selected), _) = state else {
            Issue.record("Expected a selected swap provider, got \(state)")
            return
        }

        #expect(selected.provider.id == "dex")
    }

    @Test("With the toggle off the ready DEX is preselected over a better CEX")
    func toggleOffPreselectsReadyDEX() async throws {
        let sut = makeSUT(isSwapBestRateDefaultProviderEnabled: false)

        _ = try await sut.update(pair: makePair())
        let state = try await sut.update(amountType: .from(1))

        guard case .swap(.some(let selected), _) = state else {
            Issue.record("Expected a selected swap provider, got \(state)")
            return
        }

        #expect(selected.provider.id == "dex")
    }

    @Test("With the toggle off turning the DEX preference on keeps a CEX the user picked")
    func toggleOffKeepsUserPickedCEX() async throws {
        let sut = makeSUT(isSwapBestRateDefaultProviderEnabled: false)

        _ = try await sut.update(pair: makePair())
        let loaded = try await sut.update(amountType: .from(1))

        guard case .swap(_, let providers) = loaded,
              let cex = providers.availableProviders(rate: .float).first(where: { $0.provider.id == "cex" }) else {
            Issue.record("Expected a CEX among the providers, got \(loaded)")
            return
        }

        _ = await sut.updateSelectedProvider(provider: cex)
        await sut.update(prefersDEX: true)
        let state = await sut.update(type: .autoupdate)

        guard case .swap(.some(let selected), _) = state else {
            Issue.record("Expected a selected swap provider, got \(state)")
            return
        }

        #expect(selected === cex)
    }
}

// MARK: - Helpers

private extension CommonExpressManagerBestProviderTests {
    func makeSUT(isSwapBestRateDefaultProviderEnabled: Bool = true) -> CommonExpressManager {
        CommonExpressManager(
            expressAPIProvider: ExpressAPIProviderStub(),
            expressProviderManagerFactory: QuotedProviderManagerFactory(expectAmounts: ["dex": 90, "cex": 100]),
            expressRepository: ProvidersRepositoryStub(providers: [makeProvider(id: "dex", type: .dex), makeProvider(id: "cex", type: .cex)]),
            featureFlags: ExpressFeatureFlags(isSwapBestRateDefaultProviderEnabled: isSwapBestRateDefaultProviderEnabled)
        )
    }

    func makeProvider(id: ExpressProvider.Id, type: ExpressProviderType) -> ExpressProvider {
        ExpressProvider(
            id: id,
            name: id,
            type: type,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            isCustomSlippageSupported: false
        )
    }

    func makePair() -> ExpressManagerSwappingPair {
        ExpressManagerSwappingPair(
            source: SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: "0xOwner", allowanceProvider: nil),
            destination: DestinationWalletStub(currency: ExpressWalletCurrency(
                contractAddress: "0xUSDT",
                network: "ethereum",
                decimalCount: 6,
                symbol: "USDT"
            ))
        )
    }
}

// MARK: - Doubles

private struct ProvidersRepositoryStub: ExpressRepository {
    let providers: [ExpressProvider]

    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}

    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] {
        providers
    }

    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] {
        rateType == .fixed ? [] : providers.map(\.id)
    }
}

private struct QuotedProviderManagerFactory: ExpressProviderManagerFactory {
    let expectAmounts: [ExpressProvider.Id: Decimal]

    func makeExpressProviderManager(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType
    ) throws -> ExpressAvailableProvider {
        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: pair,
            rateType: rateType,
            expressFeeProvider: FeeProviderFactoryStub().makeExpressFeeProvider(),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags()
        )

        let quote = ExpressQuote(
            fromAmount: 1,
            expectAmount: expectAmounts[provider.id] ?? 0,
            allowanceContract: nil,
            quoteId: nil,
            txType: nil,
            isRestricted: false,
            slippage: nil
        )

        return ExpressAvailableProvider(context: context, manager: QuotedProviderManagerStub(state: .restriction(.insufficientBalance(1), quote: quote)))
    }
}

private final class QuotedProviderManagerStub: ExpressProviderManager {
    private let state: ExpressProviderManagerState

    init(state: ExpressProviderManagerState) {
        self.state = state
    }

    func getState() -> ExpressProviderManagerState { state }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        throw StubError.estimateFailed
    }
}
