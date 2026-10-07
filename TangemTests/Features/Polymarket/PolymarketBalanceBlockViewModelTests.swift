//
//  PolymarketBalanceBlockViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket balance block")
@MainActor
struct PolymarketBalanceBlockViewModelTests {
    @Test("In a restricted region add funds opens the region warning, not the unavailable alert")
    func restrictedRegionWinsOverUnavailableAddFunds() async throws {
        let context = Self.makeSUT(isRegionRestricted: true)

        try await settle { context.sut.addFundsState == .unavailable }

        context.sut.handleViewAction(.openAddFunds)

        #expect(context.routable.regionWarnings == 1)
        #expect(context.routable.addFundsOpenings == 0)
        #expect(context.sut.alert == nil)
    }

    @Test("Outside a restricted region unavailable add funds explains itself")
    func unavailableAddFundsShowsAlert() async throws {
        let context = Self.makeSUT(isRegionRestricted: false)

        try await settle { context.sut.addFundsState == .unavailable }

        context.sut.handleViewAction(.openAddFunds)

        #expect(context.routable.regionWarnings == 0)
        #expect(context.sut.alert != nil)
    }

    @Test("An account funds refresh prepares them again without refreshing the balance")
    func accountFundsRefreshSkipsBalance() async throws {
        let context = Self.makeSUT()

        try await settle { context.configuration.callCount == 1 && context.balanceProvider.refreshCount == 1 }

        await context.refreshCenter.refresh(.accountFunds)

        try await settle { context.configuration.callCount == 2 }
        #expect(context.balanceProvider.refreshCount == 1)
    }

    @Test("A balance refresh refreshes the balance without preparing the account funds")
    func balanceRefreshSkipsPreparation() async throws {
        let context = Self.makeSUT()

        try await settle { context.configuration.callCount == 1 && context.balanceProvider.refreshCount == 1 }

        await context.refreshCenter.refresh(.balance)

        #expect(context.balanceProvider.refreshCount == 2)
        try await drain()
        #expect(context.configuration.callCount == 1)
    }

    @Test("A full refresh does both")
    func fullRefreshDoesBoth() async throws {
        let context = Self.makeSUT()

        try await settle { context.configuration.callCount == 1 && context.balanceProvider.refreshCount == 1 }

        await context.refreshCenter.refresh(.full)

        #expect(context.balanceProvider.refreshCount == 2)
        try await settle { context.configuration.callCount == 2 }
    }
}

// MARK: - Helpers

private extension PolymarketBalanceBlockViewModelTests {
    struct Context {
        let sut: PolymarketBalanceBlockViewModel
        let balanceProvider: BalanceProviderSpy
        let configuration: FailingConfigurationService
        let refreshCenter: PolymarketMainRefreshCenter
        let routable: BalanceBlockRoutableSpy
    }

    static func makeSUT(isRegionRestricted: Bool = false) -> Context {
        let balanceProvider = BalanceProviderSpy()
        let configuration = FailingConfigurationService()
        let refreshCenter = PolymarketMainRefreshCenter()
        let routable = BalanceBlockRoutableSpy()

        let sut = PolymarketBalanceBlockViewModel(
            balanceProvider: balanceProvider,
            accountFundsInteractor: PolymarketAccountFundsInteractor(
                bridgeService: FailingBridgeService(),
                configurationService: configuration,
                walletService: PolymarketDepositWalletServiceStub(),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(),
                supportedBlockchains: []
            ),
            fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
            isRegionRestricted: { isRegionRestricted },
            refreshCenter: refreshCenter,
            routable: routable
        )

        return Context(
            sut: sut,
            balanceProvider: balanceProvider,
            configuration: configuration,
            refreshCenter: refreshCenter,
            routable: routable
        )
    }
}

// MARK: - Doubles

private final class BalanceProviderSpy: PolymarketBalanceProvider {
    var refreshCount: Int { counter.withLock { $0 } }

    private let counter = OSAllocatedUnfairLock(initialState: 0)

    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        Just(.loaded("$10.00")).eraseToAnyPublisher()
    }

    var totalBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        Just(.loaded("$10.00")).eraseToAnyPublisher()
    }

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> {
        Just(.loaded(10)).eraseToAnyPublisher()
    }

    func refresh(scope: PolymarketBalanceRefreshScope) async {
        counter.withLock { $0 += 1 }
    }
}

private final class BalanceBlockRoutableSpy: PolymarketBalanceBlockRoutable {
    private(set) var addFundsOpenings = 0
    private(set) var regionWarnings = 0

    func openAddFunds() {
        addFundsOpenings += 1
    }

    func openWithdraw() {}

    func openRegionWarning() {
        regionWarnings += 1
    }
}

private final class FailingConfigurationService: PolymarketConfigurationService {
    var callCount: Int { counter.withLock { $0 } }

    private let counter = OSAllocatedUnfairLock(initialState: 0)

    func builderCode() async throws -> String {
        counter.withLock { $0 += 1 }
        throw BalanceBlockTestError.unavailable
    }
}

private struct FailingBridgeService: PolymarketBridgeService {
    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        throw BalanceBlockTestError.unavailable
    }

    func fundingAddresses(forDepositWallet depositWalletAddress: String, builderCode: String) async throws -> PolymarketBridgeAddresses {
        throw BalanceBlockTestError.unavailable
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        throw BalanceBlockTestError.unavailable
    }
}

private enum BalanceBlockTestError: Error {
    case unavailable
}
