//
//  PolymarketMainViewModelTests.swift
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

@MainActor
@Suite("Polymarket main screen", .timeLimit(.minutes(1)))
struct PolymarketMainViewModelTests {
    @Test("Opening the main screen reads fast trading")
    func openingReadsFastTrading() async throws {
        let fastTrading = PolymarketFastTradingServiceSpy()
        _ = makeSUT(fastTrading: fastTrading)

        try await fastTrading.refreshes.next()
    }

    @Test("The main screen warns about foreign signers without waiting for it to appear")
    func bannerShowsBeforeTheScreenAppears() async {
        let (sut, _) = makeSUT(fastTrading: Self.showingForeignSigners())

        #expect(await sut.$fastTradingBanner.firstValue { $0 != nil } == .foreignSigners)
    }

    @Test("A tapped banner opens its own screen even when the shown banner has changed since")
    func tappedBannerOpensItsScreen() async {
        let (sut, routable) = makeSUT(fastTrading: Self.showingForeignSigners())
        await sut.$fastTradingBanner.firstValue { $0 == .foreignSigners }

        sut.handleViewAction(.performFastTradingBannerAction(.reactivate))

        #expect(routable.fastTradingActivations == 1)
    }

    @Test("Closing a banner closes the tapped one even when the shown banner has changed since")
    func closingDismissesTheTappedBanner() async {
        let fastTrading = Self.showingForeignSigners()
        let (sut, _) = makeSUT(fastTrading: fastTrading)
        await sut.$fastTradingBanner.firstValue { $0 == .foreignSigners }

        sut.handleViewAction(.dismissFastTradingBanner(.reactivate))

        #expect(fastTrading.dismissedBanners == [.reactivate])
    }

    // MARK: - Content reveal

    @Test("The main screen shows its content once fast trading has settled or is off, without waiting for the region", arguments: FastTradingSetup.allCases)
    func revealsWithoutWaitingForTheRegion(_ setup: FastTradingSetup) async {
        let (sut, _) = makeSUT(fastTrading: setup.makeProvider(), geoblockState: .unknown)

        await sut.$isContentRevealed.firstValue { $0 }
    }

    @Test("The main screen keeps its content hidden while fast trading is loading and shows it after the timeout")
    func revealsByTimeoutWhileFastTradingLoads() async throws {
        let delays = PolymarketSteppedDelayProvider()
        let (sut, _) = makeSUT(fastTrading: PolymarketFastTradingServiceSpy(state: .loading), geoblockState: .blocked, revealDelays: delays)
        await sut.$isRegionRestricted.firstValue { $0 }

        #expect(!sut.isContentRevealed)

        try await delays.waitUntilParked(Delays.revealTimeout)
        delays.resume(Delays.revealTimeout)

        await sut.$isContentRevealed.firstValue { $0 }
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

extension PolymarketMainViewModelTests {
    enum FastTradingSetup: CaseIterable, Sendable {
        case settled
        case off

        @MainActor
        func makeProvider() -> PolymarketFastTradingBannerProviding? {
            switch self {
            case .settled: PolymarketMainViewModelTests.showingForeignSigners()
            case .off: nil
            }
        }
    }
}

private enum Delays {
    static let revealTimeout: TimeInterval = 1.5
}

private extension PolymarketMainViewModelTests {
    static func showingForeignSigners() -> PolymarketFastTradingServiceSpy {
        let foreignSigner = PolymarketSessionSigner(
            address: "0xf0e1000000000000000000000000000000000009",
            scopes: ["CLOB"],
            validUntil: Fixture.validUntil
        )

        return PolymarketFastTradingServiceSpy(state: .loaded(Fixture.assess(keys: [], signers: [foreignSigner])))
    }

    func makeSUT(
        fastTrading: PolymarketFastTradingBannerProviding?,
        geoblockState: PolymarketGeoblockState = .allowed,
        revealDelays: PolymarketSteppedDelayProvider = PolymarketSteppedDelayProvider()
    ) -> (sut: PolymarketMainViewModel, routable: MainRoutableSpy) {
        let routable = MainRoutableSpy()
        let refreshCenter = PolymarketMainRefreshCenter()
        let fundsArrivalTracker = PolymarketFundsArrivalTracker(balancePublisher: .empty)
        let activityHandler = PolymarketMainActivityHandler(fundsArrivalTracker: fundsArrivalTracker, refreshCenter: refreshCenter)
        let userWalletId = UserWalletId(value: Data(repeating: 0x04, count: 32))

        let sut = PolymarketMainViewModel(
            balanceViewModel: PolymarketBalanceBlockViewModel(
                balanceProvider: BalanceProviderStub(),
                accountFundsInteractor: PolymarketAccountFundsInteractor(
                    bridgeService: BridgeServiceStub(),
                    configurationService: ConfigurationServiceStub(),
                    walletService: PolymarketDepositWalletServiceStub(),
                    ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: nil),
                    supportedBlockchains: []
                ),
                fundsArrivalTracker: fundsArrivalTracker,
                withdrawalStatePublisher: .empty,
                isRegionRestricted: { false },
                refreshCenter: refreshCenter,
                routable: routable,
                appStateObserver: AppStateObserverStub(),
                delayProvider: PolymarketSteppedDelayProvider()
            ),
            positionsViewModel: PolymarketPositionsBlockViewModel(
                positionsService: nil,
                presenceStore: PolymarketAccountPresenceStoreStub(),
                userWalletId: userWalletId,
                refreshCenter: refreshCenter,
                activityHandler: activityHandler,
                routable: routable,
                appStateObserver: AppStateObserverStub(),
                delayProvider: PolymarketSteppedDelayProvider()
            ),
            searchViewModel: PolymarketSearchBlockViewModel(
                apiProvider: PolymarketAPIProviderStub(),
                activityHandler: activityHandler,
                isRegionRestricted: { false },
                usesPhaseTwoCards: false,
                routable: PolymarketEventOpeningRoutableSpy.ignored,
                debounceInterval: .zero,
                appStateObserver: AppStateObserverStub(),
                delayProvider: PolymarketSteppedDelayProvider()
            ),
            eventsViewModel: PolymarketEventsBlockViewModel(
                source: .explore(categoryOpener: PolymarketEventOpeningRoutableSpy.ignored),
                apiProvider: PolymarketAPIProviderStub(),
                refreshCenter: refreshCenter,
                activityHandler: activityHandler,
                liveQuotesTracker: PolymarketLiveQuotesSourceSpy().makeTracker(),
                liveGamesTracker: PolymarketLiveGamesSourceSpy().makeTracker(),
                usesPhaseTwoCards: false,
                showsSubcategories: false,
                isRegionRestricted: { false },
                routable: PolymarketEventOpeningRoutableSpy.ignored,
                appStateObserver: AppStateObserverStub(),
                delayProvider: HoldingDelayProviderSpy(holdThreshold: 0),
                reportOutdatedData: {}
            ),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: geoblockState),
            fundsArrivalTracker: fundsArrivalTracker,
            withdrawTracker: PolymarketWithdrawTracker(
                withdrawService: PolymarketWithdrawServiceSpy(),
                store: PolymarketWithdrawRecordStore(userWalletId: userWalletId, storage: InMemoryPersistentStorage()),
                delayProvider: PolymarketSteppedDelayProvider(),
                serverClock: PolymarketServerClock(deviceNow: { Fixture.now })
            ),
            refreshCenter: refreshCenter,
            fastTrading: fastTrading,
            revealDelayProvider: revealDelays,
            coordinator: routable
        )

        return (sut, routable)
    }
}

// MARK: - Stubs

private final class MainRoutableSpy: PolymarketMainRoutable, PolymarketBalanceBlockRoutable, PolymarketPositionsBlockRoutable {
    private(set) var fastTradingActivations = 0

    func openFastTradingActivation() {
        fastTradingActivations += 1
    }

    func dismiss() {}

    func openRegionWarning() {}

    func openHowItWorks() {}

    func openSupportChat() {}

    func openActivity() {}

    func openSettings() {}

    func openAddFunds() {}

    func openWithdraw() {}

    func openMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void
    ) {}

    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {}

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void) {}
}

private final class BalanceProviderStub: PolymarketBalanceProvider {
    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        .empty
    }

    var totalBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        .empty
    }

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> {
        .empty
    }

    func refresh(scope: PolymarketBalanceRefreshScope) async {}
}

private struct ConfigurationServiceStub: PolymarketConfigurationService {
    func builderCode() async throws -> String {
        throw CancellationError()
    }
}

private struct BridgeServiceStub: PolymarketBridgeService {
    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        throw CancellationError()
    }

    func fundingAddresses(forDepositWallet depositWalletAddress: String, builderCode: String) async throws -> PolymarketBridgeAddresses {
        throw CancellationError()
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        throw CancellationError()
    }
}
