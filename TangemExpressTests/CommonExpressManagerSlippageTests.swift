//
//  CommonExpressManagerSlippageTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("CommonExpressManager — custom slippage")
struct CommonExpressManagerSlippageTests {
    private static let slippage = Decimal(string: "0.01")!

    @Test("A pair change resets the slippage, a reload of the same pair keeps it")
    func pairChangeResetsSlippage() async throws {
        let factory = ExpressProviderManagerFactorySpy()
        let sut = makeSUT(providers: [makeProvider(id: "dex", isCustomSlippageSupported: true)], factory: factory)

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        _ = await sut.update(slippage: Self.slippage)
        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))

        #expect(await sut.getSlippage() == Self.slippage)

        _ = try await sut.update(pair: makePair(destinationSymbol: "DAI"))
        _ = try await sut.update(amountType: .from(1))

        #expect(await sut.getSlippage() == nil)
        #expect(factory.spies["dex"]?.requests.map(\.slippage) == [nil])
    }

    @Test("An amount change resets the slippage, repeating the same amount keeps it")
    func amountChangeResetsSlippage() async throws {
        let factory = ExpressProviderManagerFactorySpy()
        let sut = makeSUT(providers: [makeProvider(id: "dex", isCustomSlippageSupported: true)], factory: factory)

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        _ = try await sut.update(amountType: .from(1))
        _ = await sut.update(slippage: Self.slippage)
        _ = try await sut.update(amountType: .from(1))

        #expect(await sut.getSlippage() == Self.slippage)

        _ = try await sut.update(amountType: .from(2))

        #expect(await sut.getSlippage() == nil)
        #expect(factory.spies["dex"]?.requests.last.map(\.slippage) == .some(nil))
    }

    @Test("Only the providers that support a custom slippage reload their quotes")
    func onlySupportingProvidersReload() async throws {
        let factory = ExpressProviderManagerFactorySpy()
        let sut = makeSUT(
            providers: [
                makeProvider(id: "custom", isCustomSlippageSupported: true),
                makeProvider(id: "default", isCustomSlippageSupported: false),
            ],
            factory: factory
        )

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        _ = try await sut.update(amountType: .from(1))
        _ = await sut.update(slippage: Self.slippage)

        #expect(factory.spies["custom"]?.requests.map(\.slippage) == [nil, Self.slippage])
        #expect(factory.spies["default"]?.requests.map(\.slippage) == [nil])
    }

    @Test("Repeating the same slippage reloads the quotes again, so a cancelled reload can be retried")
    func repeatedSlippageReloadsAgain() async throws {
        let factory = ExpressProviderManagerFactorySpy()
        let sut = makeSUT(providers: [makeProvider(id: "custom", isCustomSlippageSupported: true)], factory: factory)

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        _ = try await sut.update(amountType: .from(1))
        _ = await sut.update(slippage: Self.slippage)
        _ = await sut.update(slippage: Self.slippage)

        #expect(factory.spies["custom"]?.requests.map(\.slippage) == [nil, Self.slippage, Self.slippage])
    }

    @Test("A slippage change keeps the provider the user selected")
    func slippageChangeKeepsSelection() async throws {
        let factory = ExpressProviderManagerFactorySpy()
        let sut = makeSUT(
            providers: [
                makeProvider(id: "first", isCustomSlippageSupported: true),
                makeProvider(id: "second", isCustomSlippageSupported: true),
            ],
            factory: factory
        )

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        let loaded = try await sut.update(amountType: .from(1))
        guard case .swap(let best, let providers) = loaded,
              let chosen = providers.availableProviders(rate: .float).first(where: { $0 !== best }) else {
            Issue.record("Expected two swap providers, got \(loaded)")
            return
        }
        _ = await sut.updateSelectedProvider(provider: chosen)

        let state = await sut.update(slippage: Self.slippage)

        guard case .swap(let selected, _) = state else {
            Issue.record("Expected a swap state, got \(state)")
            return
        }
        #expect(selected === chosen)
    }
}

// MARK: - Helpers

private extension CommonExpressManagerSlippageTests {
    func makeSUT(providers: [ExpressProvider], factory: ExpressProviderManagerFactorySpy) -> CommonExpressManager {
        CommonExpressManager(
            expressAPIProvider: ExpressAPIProviderStub(),
            expressProviderManagerFactory: factory,
            expressRepository: ExpressRepositoryStub(providers: providers),
            featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: false)
        )
    }

    func makeProvider(id: ExpressProvider.Id, isCustomSlippageSupported: Bool) -> ExpressProvider {
        ExpressProvider(
            id: id,
            name: id,
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            isCustomSlippageSupported: isCustomSlippageSupported
        )
    }

    func makePair(destinationSymbol: String) -> ExpressManagerSwappingPair {
        ExpressManagerSwappingPair(
            source: SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: "0xOwner", allowanceProvider: nil),
            destination: DestinationWalletStub(currency: ExpressWalletCurrency(
                contractAddress: "0x\(destinationSymbol)",
                network: "ethereum",
                decimalCount: 6,
                symbol: destinationSymbol
            ))
        )
    }
}

// MARK: - Doubles

private struct ExpressRepositoryStub: ExpressRepository {
    let providers: [ExpressProvider]

    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}

    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] {
        providers
    }

    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] {
        rateType == .fixed ? [] : providers.map(\.id)
    }
}

private final class ExpressProviderManagerFactorySpy: ExpressProviderManagerFactory {
    var spies: [ExpressProvider.Id: ExpressProviderManagerSpy] { _spies.withLock { $0 } }

    private let _spies = OSAllocatedUnfairLock(initialState: [ExpressProvider.Id: ExpressProviderManagerSpy]())

    func makeExpressProviderManager(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType
    ) throws -> ExpressAvailableProvider {
        let spy = ExpressProviderManagerSpy()
        _spies.withLock { $0[provider.id] = spy }

        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: pair,
            rateType: rateType,
            expressFeeProvider: FeeProviderFactoryStub().makeExpressFeeProvider(),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: false)
        )

        return ExpressAvailableProvider(context: context, manager: spy)
    }
}
