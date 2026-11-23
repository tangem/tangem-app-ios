//
//  CommonSwapRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress
@testable import Tangem

@Suite("Swap repository keeps each wallet's pairs and providers apart")
struct CommonSwapRepositoryTests {
    @Test("Pairs loaded for one wallet are not served to another")
    func pairsAreNotSharedBetweenWallets() async throws {
        let apiProviders = makeAPIProviders()
        let sut = makeSUT(apiProviders: apiProviders)

        try await sut.updatePairs(from: Constants.source, to: [Constants.destination], userWalletInfo: Constants.regularWallet)

        #expect(await sut.getPairs(from: Constants.source, userWalletInfo: Constants.swapKitWallet).isEmpty)

        try await sut.updatePairs(from: Constants.source, to: [Constants.destination], userWalletInfo: Constants.swapKitWallet)

        #expect(await providerIds(sut.getPairs(from: Constants.source, userWalletInfo: Constants.regularWallet)) == Constants.allProviderIds)
        #expect(await providerIds(sut.getPairs(from: Constants.source, userWalletInfo: Constants.swapKitWallet)) == [Constants.swapKitId])
    }

    @Test("Available providers of a pair come from the source wallet's own pairs")
    func availableProvidersFollowSourceWallet() async throws {
        let apiProviders = makeAPIProviders()
        let sut = makeSUT(apiProviders: apiProviders)

        try await sut.updatePairs(from: Constants.source, to: [Constants.destination], userWalletInfo: Constants.regularWallet)
        try await sut.updatePairs(from: Constants.source, to: [Constants.destination], userWalletInfo: Constants.swapKitWallet)

        let regularIds = await sut.getAvailableProvidersIds(for: makeSwappingPair(wallet: Constants.regularWallet), rateType: nil)
        let swapKitIds = await sut.getAvailableProvidersIds(for: makeSwappingPair(wallet: Constants.swapKitWallet), rateType: nil)

        #expect(regularIds == Constants.allProviderIds)
        #expect(swapKitIds == [Constants.swapKitId])
    }

    @Test("Providers fetched for one wallet are not served to another")
    func providersAreNotSharedBetweenWallets() async throws {
        let apiProviders = makeAPIProviders()
        let sut = makeSUT(apiProviders: apiProviders)

        let regularProviders = try await sut.providers(userWalletInfo: Constants.regularWallet)
        let swapKitProviders = try await sut.providers(userWalletInfo: Constants.swapKitWallet)

        #expect(regularProviders.map(\.id) == Constants.allProviderIds)
        #expect(swapKitProviders.map(\.id) == [Constants.swapKitId])
        #expect(apiProviders.providersCallsCount(walletId: Constants.swapKitWallet.id.stringValue) == 1)
    }

    @Test("Providers of a wallet are fetched once and then served from its cache")
    func providersAreCachedPerWallet() async throws {
        let apiProviders = makeAPIProviders()
        let sut = makeSUT(apiProviders: apiProviders)

        _ = try await sut.providers(userWalletInfo: Constants.swapKitWallet)
        let providers = try await sut.providers(userWalletInfo: Constants.swapKitWallet)

        #expect(providers.map(\.id) == [Constants.swapKitId])
        #expect(apiProviders.providersCallsCount(walletId: Constants.swapKitWallet.id.stringValue) == 1)
    }
}

// MARK: - Helpers

private extension CommonSwapRepositoryTests {
    func makeSUT(apiProviders: APIProvidersSpy) -> CommonSwapRepository {
        CommonSwapRepository { userWalletId, _ in
            apiProviders.provider(walletId: userWalletId)
        }
    }

    func makeAPIProviders() -> APIProvidersSpy {
        APIProvidersSpy(providerIdsByWalletId: [
            Constants.regularWallet.id.stringValue: Constants.allProviderIds,
            Constants.swapKitWallet.id.stringValue: [Constants.swapKitId],
        ])
    }

    func makeSwappingPair(wallet: UserWalletInfo) -> ExpressManagerSwappingPair {
        let walletInfo = ExpressWalletInfo(id: wallet.id.stringValue, refcode: nil)

        return ExpressManagerSwappingPair(
            source: ExpressSourceWalletStub(walletInfo: walletInfo, currency: Constants.source),
            destination: ExpressSourceWalletStub(walletInfo: walletInfo, currency: Constants.destination)
        )
    }

    func providerIds(_ pairs: [ExpressPair]) -> [ExpressProvider.Id] {
        pairs.flatMap(\.providers).map(\.id)
    }

    static func makeUserWalletInfo(idByte: UInt8) -> UserWalletInfo {
        UserWalletInfo(
            name: "Wallet \(idByte)",
            id: UserWalletId(value: Data([idByte])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    enum Constants {
        static let swapKitId: ExpressProvider.Id = "swapkit"
        static let allProviderIds: [ExpressProvider.Id] = ["changenow", swapKitId]

        static let source = ExpressWalletCurrency(contractAddress: "coin", network: "ethereum", decimalCount: 18, symbol: "ETH")
        static let destination = ExpressWalletCurrency(contractAddress: "usdt", network: "ethereum", decimalCount: 6, symbol: "USDT")

        static var regularWallet: UserWalletInfo { CommonSwapRepositoryTests.makeUserWalletInfo(idByte: 0x01) }
        static var swapKitWallet: UserWalletInfo { CommonSwapRepositoryTests.makeUserWalletInfo(idByte: 0x02) }
    }
}

// MARK: - Stubs

private final class APIProvidersSpy: Sendable {
    private let providerIdsByWalletId: [String: [ExpressProvider.Id]]
    private let providersCallsByWalletId = OSAllocatedUnfairLock(initialState: [String: Int]())

    init(providerIdsByWalletId: [String: [ExpressProvider.Id]]) {
        self.providerIdsByWalletId = providerIdsByWalletId
    }

    func providersCallsCount(walletId: String) -> Int {
        providersCallsByWalletId.withLock { $0[walletId] ?? 0 }
    }

    func provider(walletId: String) -> ExpressAPIProvider {
        let providerIds = providerIdsByWalletId[walletId] ?? []
        let stub = ExpressAPIProviderStub()

        stub.pairsHandler = { from, to in
            from.flatMap { source in
                to.map { destination in
                    ExpressPair(
                        source: source.asCurrency,
                        destination: destination.asCurrency,
                        providers: providerIds.map { ExpressPairProvider(id: $0, rates: [.float]) }
                    )
                }
            }
        }

        stub.providersHandler = { [providersCallsByWalletId] _ in
            providersCallsByWalletId.withLock { $0[walletId, default: 0] += 1 }
            return providerIds.map(Self.makeProvider)
        }

        return stub
    }

    private static func makeProvider(id: ExpressProvider.Id) -> ExpressProvider {
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
}

private struct ExpressSourceWalletStub: ExpressSourceWallet {
    let walletInfo: ExpressWalletInfo
    let currency: ExpressWalletCurrency

    var coinCurrency: ExpressWalletCurrency { currency }
    var address: String? { nil }
    var extraId: String? { nil }

    var allowanceProvider: AllowanceProvider? { nil }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { nil }
    var balanceProvider: BalanceProvider { fatalError("Not used in tests") }
    var analyticsLogger: AnalyticsLogger { fatalError("Not used in tests") }
    var providerTransactionValidator: ExpressProviderTransactionValidator { fatalError("Not used in tests") }
    var operationType: ExpressOperationType { fatalError("Not used in tests") }
    var supportedProvidersFilter: SupportedProvidersFilter { fatalError("Not used in tests") }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { fatalError("Not used in tests") }
}
