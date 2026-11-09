//
//  CommonExpressManagerHiddenProviderTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("CommonExpressManager — a provider hidden after an exchange-data error")
struct CommonExpressManagerHiddenProviderTests {
    @Test("A hiding error drops the provider and selects the best of the rest")
    func hidingErrorDropsProvider() async throws {
        let sut = makeSUT(failures: ["changelly": ExpressAPIError(code: 2200, value: nil)])

        try await selectChangelly(in: sut)
        await #expect(throws: ExpressExchangeDataError.self) { try await sut.requestData() }

        let state = await sut.update(type: .autoupdate)
        #expect(providerIds(in: state) == ["changenow"])
        #expect(selectedId(in: state) == "changenow")
    }

    @Test("An error the user fixes keeps the provider")
    func userFixableErrorKeepsProvider() async throws {
        let sut = makeSUT(failures: ["changelly": ExpressAPIError(code: 2250, value: nil)])

        try await selectChangelly(in: sut)
        await #expect(throws: ExpressExchangeDataError.self) { try await sut.requestData() }

        let state = await sut.update(type: .autoupdate)
        #expect(providerIds(in: state) == ["changelly", "changenow"])
        #expect(selectedId(in: state) == "changelly")
    }

    @Test("The provider stays hidden across an amount change and a reload of the same pair")
    func hiddenAcrossAmountAndSamePair() async throws {
        let sut = makeSUT(failures: ["changelly": URLError(.timedOut)])

        try await selectChangelly(in: sut)
        await #expect(throws: ExpressExchangeDataError.self) { try await sut.requestData() }

        #expect(try await providerIds(in: sut.update(amountType: .from(2))) == ["changenow"])
        #expect(try await providerIds(in: sut.update(pair: makePair(destinationSymbol: "USDT"))) == ["changenow"])
    }

    @Test("A pair change brings the provider back")
    func pairChangeBringsProviderBack() async throws {
        let sut = makeSUT(failures: ["changelly": URLError(.timedOut)])

        try await selectChangelly(in: sut)
        await #expect(throws: ExpressExchangeDataError.self) { try await sut.requestData() }

        #expect(try await providerIds(in: sut.update(pair: makePair(destinationSymbol: "DAI"))) == ["changelly", "changenow"])
    }

    @Test("Hiding the only provider leaves the pair without providers")
    func hidingOnlyProviderEmptiesPair() async throws {
        let sut = makeSUT(providerIds: ["changelly"], failures: ["changelly": URLError(.timedOut)])

        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        _ = try await sut.update(amountType: .from(1))
        await #expect(throws: ExpressExchangeDataError.self) { try await sut.requestData() }

        let state = await sut.update(type: .autoupdate)
        #expect(providerIds(in: state).isEmpty)
        #expect(selectedId(in: state) == nil)
    }
}

// MARK: - Helpers

private extension CommonExpressManagerHiddenProviderTests {
    func makeSUT(
        providerIds: [ExpressProvider.Id] = ["changelly", "changenow"],
        failures: [ExpressProvider.Id: Error]
    ) -> CommonExpressManager {
        CommonExpressManager(
            expressAPIProvider: ExpressAPIProviderStub(),
            expressProviderManagerFactory: FailingSendDataFactory(failures: failures),
            expressRepository: CEXRepositoryStub(providers: providerIds.map { makeProvider(id: $0) }),
            featureFlags: ExpressFeatureFlags(isSwapBestRateDefaultProviderEnabled: false, isHideRejectedSwapProvidersEnabled: false)
        )
    }

    func selectChangelly(in sut: CommonExpressManager) async throws {
        _ = try await sut.update(pair: makePair(destinationSymbol: "USDT"))
        let state = try await sut.update(amountType: .from(1))

        guard case .swap(_, let providers) = state,
              let changelly = providers.availableProviders(rate: .float).first(where: { $0.provider.id == "changelly" }) else {
            Issue.record("Expected Changelly among the providers, got \(state)")
            return
        }

        _ = await sut.updateSelectedProvider(provider: changelly)
    }

    func providerIds(in state: ExpressManagerState) -> [ExpressProvider.Id] {
        guard case .swap(_, let providers) = state else { return [] }
        return providers.availableProviders(rate: .float).map(\.provider.id)
    }

    func selectedId(in state: ExpressManagerState) -> ExpressProvider.Id? {
        guard case .swap(let selected, _) = state else { return nil }
        return selected?.provider.id
    }

    func makeProvider(id: ExpressProvider.Id) -> ExpressProvider {
        ExpressProvider(
            id: id,
            name: id,
            type: .cex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            isCustomSlippageSupported: false
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

private struct CEXRepositoryStub: ExpressRepository {
    let providers: [ExpressProvider]

    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}

    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] {
        providers
    }

    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] {
        rateType == .fixed ? [] : providers.map(\.id)
    }
}

private final class FailingSendDataFactory: ExpressProviderManagerFactory {
    private let failures: [ExpressProvider.Id: Error]

    init(failures: [ExpressProvider.Id: Error]) {
        self.failures = failures
    }

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
            featureFlags: ExpressFeatureFlags(isSwapBestRateDefaultProviderEnabled: false, isHideRejectedSwapProvidersEnabled: true)
        )

        let manager = FailingSendDataProviderManager(
            failure: failures[provider.id].map { ExpressExchangeDataError(provider: provider, currencySymbol: "", underlying: $0) }
        )

        return ExpressAvailableProvider(context: context, manager: manager)
    }
}

private final class FailingSendDataProviderManager: ExpressProviderManager {
    private let failure: Error?

    init(failure: Error?) {
        self.failure = failure
    }

    func getState() -> ExpressProviderManagerState { .idle }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        throw failure ?? StubError.notImplemented
    }
}
