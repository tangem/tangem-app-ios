//
//  PolymarketWidgetProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("Polymarket feed widget visibility")
@MainActor
struct PolymarketWidgetProviderTests {
    @Test("A wallet enrolled in the experiment sees the widget before it has an account")
    func enrolledWalletWithoutAccountSeesWidget() async throws {
        let widget = try await resolvedWidget(
            wallets: [makeWallet()],
            experimentService: ExperimentServiceStub(storedVariant: .on),
            hasAccount: false,
            expectsWidget: true
        )

        #expect(widget == .polymarket)
    }

    @Test("A wallet with an account keeps the widget when the experiment is off", arguments: [true, false])
    func walletWithAccountKeepsWidgetWithExperimentOff(isToggleOn: Bool) async throws {
        let widget = try await resolvedWidget(
            wallets: [makeWallet()],
            experimentService: ExperimentServiceStub(storedVariant: .control),
            isToggleOn: isToggleOn,
            hasAccount: true,
            expectsWidget: true
        )

        #expect(widget == .polymarket)
    }

    @Test("A wallet without an account does not see the widget when the experiment is off", arguments: [
        ExperimentFeatureVariantKey.control,
        nil,
    ] as [ExperimentFeatureVariantKey?])
    func walletWithoutAccountHidesWidgetWithExperimentOff(variant: ExperimentFeatureVariantKey?) async throws {
        let widget = try await resolvedWidget(
            wallets: [makeWallet()],
            experimentService: ExperimentServiceStub(storedVariant: variant),
            hasAccount: false,
            expectsWidget: false
        )

        #expect(widget == nil)
    }

    @Test("A wallet with an account sees the widget before this session's variants arrive")
    func walletWithAccountSeesWidgetWithoutFreshVariants() async throws {
        let widget = try await resolvedWidget(
            wallets: [makeWallet()],
            experimentService: ExperimentServiceStub(storedVariant: ExperimentFeatureVariantKey.on.rawValue, isFetched: false),
            hasAccount: true,
            expectsWidget: true
        )

        #expect(widget == .polymarket)
    }

    @Test("Without a wallet that supports Polymarket the widget stays hidden", arguments: [true, false])
    func noSupportingWalletHidesWidget(hasLockedWallet: Bool) async throws {
        let widget = try await resolvedWidget(
            wallets: hasLockedWallet ? [makeWallet(isLocked: true)] : [],
            experimentService: ExperimentServiceStub(storedVariant: .on),
            hasAccount: true,
            expectsWidget: false
        )

        #expect(widget == nil)
    }

    @Test("An account on any supporting wallet shows the widget and offers every supporting wallet")
    func accountOnSecondWalletShowsWidgetForAllWallets() async throws {
        let firstWallet = makeWallet(id: 0xAA)
        let secondWallet = makeWallet(id: 0xBB)
        let router = PredictionsFeedRouterStub()

        let widget = try await resolvedWidget(
            wallets: [firstWallet, secondWallet],
            experimentService: ExperimentServiceStub(storedVariant: .control),
            presenceStore: PerWalletPresenceStoreStub(walletIdsWithAccount: [secondWallet.userWalletId]),
            router: router,
            expectsWidget: true,
            selectsWidget: true
        )

        #expect(widget == .polymarket)
        #expect(router.openedWalletIds == [firstWallet.userWalletId, secondWallet.userWalletId])
    }

    @Test("Without an account on any supporting wallet the widget stays hidden when the experiment is off")
    func noAccountOnAnyWalletHidesWidget() async throws {
        let widget = try await resolvedWidget(
            wallets: [makeWallet(id: 0xAA), makeWallet(id: 0xBB)],
            experimentService: ExperimentServiceStub(storedVariant: .control),
            presenceStore: PerWalletPresenceStoreStub(walletIdsWithAccount: []),
            expectsWidget: false
        )

        #expect(widget == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketWidgetProviderTests {
    func makeWallet(id: UInt8 = 0xAA, isLocked: Bool = false) -> UserWalletModel {
        FakeUserWalletModel(
            userWalletName: "Wallet",
            isUserWalletLocked: isLocked,
            isDelayed: false,
            cardsCount: 1,
            userWalletId: UserWalletId(value: Data([id])),
            walletManagers: [],
            config: UserWalletConfigStubs.walletV2Stub
        )
    }

    func resolvedWidget(
        wallets: [UserWalletModel],
        experimentService: ExperimentServiceStub,
        isToggleOn: Bool = true,
        hasAccount: Bool,
        expectsWidget: Bool
    ) async throws -> FeedWidget? {
        try await resolvedWidget(
            wallets: wallets,
            experimentService: experimentService,
            isToggleOn: isToggleOn,
            presenceStore: PolymarketAccountPresenceStoreStub(known: hasAccount),
            expectsWidget: expectsWidget
        )
    }

    func resolvedWidget(
        wallets: [UserWalletModel],
        experimentService: ExperimentServiceStub,
        isToggleOn: Bool = true,
        presenceStore: PolymarketAccountPresenceStore,
        router: PredictionsFeedRouterStub = PredictionsFeedRouterStub(),
        expectsWidget: Bool,
        selectsWidget: Bool = false
    ) async throws -> FeedWidget? {
        let availabilityProvider = CommonPolymarketAvailabilityProvider(
            experimentService: experimentService,
            isToggleOn: { isToggleOn }
        )

        return try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousAvailabilityProvider = InjectedValues[\.polymarketAvailabilityProvider]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: wallets)
            InjectedValues[\.polymarketAvailabilityProvider] = availabilityProvider

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.polymarketAvailabilityProvider] = previousAvailabilityProvider
            }

            let sut = PolymarketWidgetProvider(router: router, presenceStore: presenceStore)
            var latestWidget: FeedWidget?
            let subscription = sut.widgetPublisher.sink { latestWidget = $0 }

            if expectsWidget {
                try await settle { latestWidget == .polymarket }
            } else {
                try await drain()
            }

            if selectsWidget {
                sut.select()
            }

            subscription.cancel()

            return latestWidget
        }
    }
}

private final class PredictionsFeedRouterStub: PredictionsFeedRoutable {
    private(set) var openedWalletIds: [UserWalletId] = []

    func openPolymarket(wallets: [UserWalletModel]) {
        openedWalletIds = wallets.map(\.userWalletId)
    }
}

private final class PerWalletPresenceStoreStub: PolymarketAccountPresenceStore {
    private let walletIdsWithAccount: Set<UserWalletId>

    init(walletIdsWithAccount: Set<UserWalletId>) {
        self.walletIdsWithAccount = walletIdsWithAccount
    }

    func hasAccount(userWalletId: UserWalletId) -> Bool {
        walletIdsWithAccount.contains(userWalletId)
    }

    func markAccountExists(for userWalletId: UserWalletId) {}

    func hadPositions(userWalletId: UserWalletId) -> Bool {
        false
    }

    func markPositionsExisted(for userWalletId: UserWalletId) {}

    func shownPositionsCount(userWalletId: UserWalletId) -> Int? {
        nil
    }

    func setShownPositionsCount(_ count: Int, for userWalletId: UserWalletId) {}

    func delete(userWalletId: UserWalletId) {}
}
