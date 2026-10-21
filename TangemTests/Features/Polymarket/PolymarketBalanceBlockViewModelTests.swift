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

    @Test("A restricted region does not stand between the user and their money: withdraw still opens")
    func restrictedRegionStillOpensWithdraw() async throws {
        let context = Self.makeSUT(isRegionRestricted: true, isAccountPrepared: true)

        try await settle { context.sut.withdrawState == .available }

        context.sut.handleViewAction(.openWithdraw)

        #expect(context.routable.withdrawOpenings == 1)
        #expect(context.routable.regionWarnings == 0)
        #expect(context.sut.alert == nil)
    }

    @Test("In a restricted region an unavailable withdraw explains itself, not the region")
    func restrictedRegionUnavailableWithdrawShowsAlert() async throws {
        let context = Self.makeSUT(isRegionRestricted: true)

        try await settle { context.sut.withdrawState == .unavailable(.accountUnavailable) }

        context.sut.handleViewAction(.openWithdraw)

        #expect(context.routable.withdrawOpenings == 0)
        #expect(context.routable.regionWarnings == 0)
        #expect(context.sut.alert != nil)
    }

    @Test("Without a known bridge minimum a withdraw tap explains itself instead of opening the withdrawal")
    func unknownMinimumWithdrawShowsAlert() async throws {
        let context = Self.makeSUT(isAccountPrepared: true, isBridgeReachable: false)

        try await settle { context.sut.withdrawState == .unavailable(.minimumUnknown) }

        context.sut.handleViewAction(.openWithdraw)

        #expect(context.routable.withdrawOpenings == 0)
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
        let configuration: ConfigurationServiceStub
        let refreshCenter: PolymarketMainRefreshCenter
        let routable: BalanceBlockRoutableSpy
    }

    static var readyWalletService: PolymarketDepositWalletServiceStub {
        PolymarketDepositWalletServiceStub(
            status: .readyToTrade,
            depositWalletAddress: try! PolymarketDepositWalletDeriver.derive(
                ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress
            )
        )
    }

    static func makeSUT(
        isRegionRestricted: Bool = false,
        isAccountPrepared: Bool = false,
        isBridgeReachable: Bool = true
    ) -> Context {
        let balanceProvider = BalanceProviderSpy()
        let configuration = ConfigurationServiceStub(fails: !isAccountPrepared)
        let refreshCenter = PolymarketMainRefreshCenter()
        let routable = BalanceBlockRoutableSpy()

        let sut = PolymarketBalanceBlockViewModel(
            balanceProvider: balanceProvider,
            accountFundsInteractor: PolymarketAccountFundsInteractor(
                bridgeService: BridgeServiceStub(fails: !isAccountPrepared || !isBridgeReachable),
                configurationService: configuration,
                walletService: isAccountPrepared ? Self.readyWalletService : PolymarketDepositWalletServiceStub(),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(
                    derived: isAccountPrepared ? PolymarketOwnerAddressProviderStub.ownerAddress : nil
                ),
                supportedBlockchains: []
            ),
            fundsArrivalTracker: PolymarketFundsArrivalTracker(balancePublisher: Empty().eraseToAnyPublisher()),
            withdrawalStatePublisher: Empty().eraseToAnyPublisher(),
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
    private(set) var withdrawOpenings = 0
    private(set) var regionWarnings = 0

    func openAddFunds() {
        addFundsOpenings += 1
    }

    func openWithdraw() {
        withdrawOpenings += 1
    }

    func openRegionWarning() {
        regionWarnings += 1
    }
}

private final class ConfigurationServiceStub: PolymarketConfigurationService {
    var callCount: Int { counter.withLock { $0 } }

    private let fails: Bool
    private let counter = OSAllocatedUnfairLock(initialState: 0)

    init(fails: Bool) {
        self.fails = fails
    }

    func builderCode() async throws -> String {
        counter.withLock { $0 += 1 }

        if fails { throw BalanceBlockTestError.unavailable }

        return "0x" + String(repeating: "0", count: 63) + "1"
    }
}

private struct BridgeServiceStub: PolymarketBridgeService {
    let fails: Bool

    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        if fails { throw BalanceBlockTestError.unavailable }

        return [
            PolymarketSupportedAsset(
                chainId: "137",
                chainName: "Polygon",
                family: .evm,
                token: PolymarketSupportedAsset.Token(
                    name: "USDC",
                    symbol: "USDC",
                    address: PolymarketUtilities.usdcContractAddress,
                    decimalCount: 6
                ),
                minCheckoutUSD: 2
            ),
        ]
    }

    func fundingAddresses(forDepositWallet depositWalletAddress: String, builderCode: String) async throws -> PolymarketBridgeAddresses {
        if fails { throw BalanceBlockTestError.unavailable }

        return PolymarketBridgeAddresses(addresses: [.evm: "0x2222222222222222222222222222222222222222"])
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        if fails { throw BalanceBlockTestError.unavailable }

        return PolymarketBridgeAddresses(addresses: [.evm: "0x2222222222222222222222222222222222222222"])
    }
}

private enum BalanceBlockTestError: Error {
    case unavailable
}
