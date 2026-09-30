//
//  MainScreenDeeplinkResponderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Main screen deeplink routing", .serialized)
@MainActor
struct MainScreenDeeplinkResponderTests {
    @Test("What the main screen can open itself, it opens as a tap would")
    func opensNativeRoute() async {
        await withMainScreen { responder, coordinator in
            let shown = responder.didReceiveIncomingAction(Constants.tokenChartAction)

            #expect(shown)
            #expect(coordinator.openedMarketsTokenId == Constants.tokenId)
        }
    }

    @Test("A screen pushed over the main screen leaves the link to whoever shows it over")
    func passesOnWhileRootIsCovered() async {
        await withMainScreen { responder, coordinator in
            coordinator.isRootVisible = false

            let shown = responder.didReceiveIncomingAction(Constants.tokenChartAction)

            #expect(!shown)
            #expect(coordinator.openedMarketsTokenId == nil)
        }
    }

    @Test("An expanded markets shtorka leaves the link to whoever shows it over")
    func passesOnWhileShtorkaIsExpanded() async {
        await withMainScreen { responder, coordinator in
            InjectedValues[\.mainBottomSheetUIManager].setExpanded(true)

            let shown = responder.didReceiveIncomingAction(Constants.tokenChartAction)

            #expect(!shown)
            #expect(coordinator.openedMarketsTokenId == nil)
        }
    }

    @Test("A destination the main screen has no route for is passed on")
    func passesOnWhatItCannotOpen() async {
        await withMainScreen { responder, _ in
            let shown = responder.didReceiveIncomingAction(.navigation(.markets(MarketsDeeplink(order: nil, interval: nil))))

            #expect(!shown)
        }
    }

    @Test("A shtorka link opens the sheet the main screen already has, on the section and filter it names")
    func opensTheShtorkaItAlreadyHas() async {
        await withMainScreen { responder, coordinator in
            let shown = responder.didReceiveIncomingAction(Constants.shtorkaAction)

            #expect(shown)
            #expect(coordinator.openedFeed == .earn(type: .staking))
        }
    }

    @Test("A shtorka link lands while the shtorka is already expanded")
    func opensTheShtorkaWhileItIsExpanded() async {
        await withMainScreen { responder, coordinator in
            InjectedValues[\.mainBottomSheetUIManager].setExpanded(true)

            let shown = responder.didReceiveIncomingAction(Constants.shtorkaAction)

            #expect(shown)
            #expect(coordinator.openedFeed == .earn(type: .staking))
        }
    }

    @Test("A screen pushed over the main screen leaves the shtorka link to whoever shows it over")
    func passesOnShtorkaWhileRootIsCovered() async {
        await withMainScreen { responder, coordinator in
            coordinator.isRootVisible = false

            let shown = responder.didReceiveIncomingAction(Constants.shtorkaAction)

            #expect(!shown)
            #expect(coordinator.openedFeed == nil)
        }
    }

    @Test("A token link naming a wallet this device doesn't have is passed on rather than waited for")
    func passesOnTokenOfUnknownWallet() async {
        await withMainScreen { responder, _ in
            let deeplink = TokenDeeplink(tokenId: Constants.tokenId, networkId: Constants.tokenId, userWalletId: "no such wallet")

            let shown = responder.didReceiveIncomingAction(.navigation(.token(deeplink)))

            #expect(!shown)
        }
    }

    @Test("A campaign link opens the campaign that is still owed")
    func opensOwedCampaign() async {
        await withMainScreen { responder, coordinator in
            await withPendingCampaign(Constants.campaignKey) {
                let shown = responder.didReceiveIncomingAction(Constants.campaignAction)

                #expect(shown)
                #expect(coordinator.openedCampaignKey == Constants.campaignKey)
            }
        }
    }

    /// The welcome flow spends the key before the main screen is ever reached, and the link it arrived with
    /// outlives that — it must not open the campaign a second time.
    @Test("A campaign link asks for nothing once nothing is owed")
    func passesOnSpentCampaign() async {
        await withMainScreen { responder, coordinator in
            await withPendingCampaign(nil) {
                let shown = responder.didReceiveIncomingAction(Constants.campaignAction)

                #expect(!shown)
                #expect(coordinator.openedCampaignKey == nil)
            }
        }
    }

    @Test("A link naming a wallet this device doesn't have is passed on")
    func passesOnUnknownWallet() async {
        await withMainScreen { responder, coordinator in
            let shown = responder.didReceiveIncomingAction(.navigation(.buy(BuyDeeplink(userWalletId: "no such wallet"))))

            #expect(!shown)
            #expect(!coordinator.didOpenBuy)
        }
    }

    @Test(
        "A joint account link naming a wallet this device doesn't have is passed on",
        .enabled(if: FeatureProvider.isAvailable(.jointAccounts))
    )
    func passesOnJointAccountOfUnknownWallet() async {
        await withMainScreen { responder, coordinator in
            let deeplink = JointAccountDeeplink(entry: .members, userWalletId: "no such wallet", accountId: "BA910A77")

            let shown = responder.didReceiveIncomingAction(.navigation(.jointAccount(deeplink)))

            #expect(!shown)
            #expect(coordinator.selectedUserWalletId == nil)
            #expect(!coordinator.didOpenJointAccountMembers)
        }
    }
}

// MARK: - Environment

private extension MainScreenDeeplinkResponderTests {
    func withMainScreen(_ body: (MainScreenDeeplinkResponder, MainScreenDeeplinkRoutableSpy) async -> Void) async {
        await withRepository {
            let coordinator = MainScreenDeeplinkRoutableSpy()
            let responder = MainScreenDeeplinkResponder()
            responder.coordinator = coordinator

            InjectedValues[\.mainBottomSheetUIManager].setExpanded(false)

            defer { InjectedValues[\.mainBottomSheetUIManager].setExpanded(false) }

            await body(responder, coordinator)
        }
    }

    func withRepository(_ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])

            defer { InjectedValues[\.userWalletRepository] = previousRepository }

            await body()
        }
    }

    func withPendingCampaign(_ campaignKey: String?, _ body: () async -> Void) async {
        let previousKey = AppSettings.shared.pendingTangemPayCampaignKey
        AppSettings.shared.pendingTangemPayCampaignKey = campaignKey

        defer { AppSettings.shared.pendingTangemPayCampaignKey = previousKey }

        await body()
    }

    enum Constants {
        static let tokenId = "bitcoin"
        static let tokenChartAction = IncomingAction.navigation(.tokenChart(TokenChartDeeplink(tokenId: tokenId)))
        static let campaignKey = "tpay_for_harvard123"
        static let campaignAction = IncomingAction.navigation(.payCustomCard(PayCustomCardDeeplink(campaignKey: campaignKey)))
        static let shtorkaAction = IncomingAction.navigation(
            .feed(FeedDeeplink(section: "earn", category: nil, type: "staking"))
        )
    }
}
