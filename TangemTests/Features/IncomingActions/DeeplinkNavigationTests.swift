//
//  DeeplinkNavigationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

/// What each destination knows about opening itself, which is all a responder needs from it. The answer
/// «nothing to open» is the interesting half: it is what sends a link further down the chain.
@Suite("Deeplink navigation", .serialized)
@MainActor
struct DeeplinkNavigationTests {
    @Test("Buy and sell open on the wallet the link names")
    func buyAndSellNameTheirWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let buy = BuyDeeplink(userWalletId: InjectedEnvironment.otherWalletId).findUserWalletModel()
            let sell = SellDeeplink(userWalletId: nil).findUserWalletModel()

            #expect(buy?.userWalletId.stringValue == InjectedEnvironment.otherWalletId)
            #expect(sell?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
        }
    }

    @Test("A wallet this device doesn't have leaves buy with nothing to open")
    func buyWithUnknownWalletOpensNothing() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let buy = BuyDeeplink(userWalletId: InjectedEnvironment.unknownWalletId).findUserWalletModel()

            #expect(buy == nil)
        }
    }

    @Test("Markets carries the filter the link asked for")
    func marketsFilter() {
        let filter = MarketsDeeplink(order: "buyers", interval: "1w").filter

        #expect(filter.order == .buyers)
        #expect(filter.interval == .week)
    }

    @Test("An invalid order and interval fall back independently")
    func marketsFilterFallsBack() {
        let filter = MarketsDeeplink(order: "nonsense", interval: "1w").filter

        #expect(filter.order == .rating)
        #expect(filter.interval == .week)
    }

    @Test("Earn keeps the type the link named")
    func earnFilterType() {
        #expect(EarnDeeplink(earnType: "yield", networkId: "ethereum").filterType == .yield)
        #expect(EarnDeeplink(earnType: "nonsense", networkId: nil).filterType == nil)
    }

    @Test("A yield link falls back to the Earn list of the network it named, when we support it")
    func yieldFallbackNetwork() {
        #expect(YieldDeeplink(tokenId: nil, networkId: "ethereum", userWalletId: nil, derivationPath: nil).earnFallbackNetworkId == "ethereum")
        #expect(YieldDeeplink(tokenId: nil, networkId: "no-such-chain", userWalletId: nil, derivationPath: nil).earnFallbackNetworkId == nil)
    }

    @Test("Onboarding reached by a link is not the same as one reached by a tap")
    func onboardingSource() {
        let link = "tangem://onboard-visa?entry=e&id=1"

        guard case .deeplink(let carried) = OnboardVisaDeeplink(deeplinkString: link).onboardingSource else {
            Issue.record("Expected the link to be carried into the onboarding")
            return
        }

        #expect(carried == link)
        #expect(OnboardVisaDeeplink(deeplinkString: nil).onboardingSource.isOther)
    }

    // MARK: - Token

    @Test(
        "A token link carrying a transaction status opens the details on that transaction",
        arguments: [
            (TokenDeeplink.StatusUpdate.Kind.onramp, PendingTransactionDetails.TransactionType.onramp),
            (TokenDeeplink.StatusUpdate.Kind.swap, PendingTransactionDetails.TransactionType.swap),
        ]
    )
    func statusUpdateBecomesPendingTransaction(
        kind: TokenDeeplink.StatusUpdate.Kind,
        expectedType: PendingTransactionDetails.TransactionType
    ) {
        let deeplink = TokenDeeplink(
            tokenId: "ethereum",
            networkId: "ethereum",
            statusUpdate: .init(kind: kind, transactionId: Constants.transactionId)
        )

        #expect(deeplink.pendingTransactionDetails?.id == Constants.transactionId)
        #expect(deeplink.pendingTransactionDetails?.type == expectedType)
    }

    @Test("A token link without a transaction status opens the details on nothing in particular")
    func tokenWithoutStatusUpdateHasNoPendingTransaction() {
        let deeplink = TokenDeeplink(tokenId: "ethereum", networkId: "ethereum")

        #expect(deeplink.pendingTransactionDetails == nil)
    }

    @Test("A token link finds the token the wallet holds")
    func tokenLinkFindsTheToken() async {
        await InjectedEnvironment().run {
            let tokenItem = CommonWalletModel.mockETH.tokenItem
            let deeplink = TokenDeeplink(
                tokenId: tokenItem.id?.lowercased() ?? "",
                networkId: tokenItem.blockchain.networkId.lowercased()
            )

            let target = await deeplink.findTarget()

            #expect(target?.walletModel.tokenItem == tokenItem)
        }
    }

    // MARK: - Payment account

    @Test(
        "The screen a payment account link names becomes what the account opens with",
        arguments: [
            ("add_funds", TangemPayOpeningAction.addFunds),
            ("current_plan", TangemPayOpeningAction.currentPlan),
            ("order_card", TangemPayOpeningAction.orderCard),
        ]
    )
    func screenBecomesIncomingAction(screen: String, expected: TangemPayOpeningAction) {
        let deeplink = TangemPayAccountDeeplink(screen: screen, userWalletId: nil)

        #expect(deeplink.openingAction == expected)
    }

    @Test("A screen name the account doesn't know leaves it to open on its own main screen")
    func unknownScreenLeavesNoIncomingAction() {
        #expect(TangemPayAccountDeeplink(screen: "no such screen", userWalletId: nil).openingAction == nil)
        #expect(TangemPayAccountDeeplink(screen: nil, userWalletId: nil).openingAction == nil)
    }

    // MARK: - Wallets this device doesn't have

    @Test("A referral link naming a wallet this device doesn't have has nothing to open")
    func referralWithUnknownWalletOpensNothing() async {
        await InjectedEnvironment().run {
            let deeplink = ReferralDeeplink(userWalletId: InjectedEnvironment.unknownWalletId)

            #expect(deeplink.makeInput() == nil)
        }
    }

    @Test("A payment account link naming a wallet this device doesn't have has nothing to open")
    func paymentAccountWithUnknownWalletOpensNothing() async {
        await InjectedEnvironment().run {
            let deeplink = TangemPayAccountDeeplink(screen: nil, userWalletId: InjectedEnvironment.unknownWalletId)

            #expect(deeplink.findUserWalletModel() == nil)
        }
    }

    // MARK: - Tokens that can't do what the link asks

    @Test("A staking link opens the staking screen on the token the wallet holds")
    func stakingOpensOnTheHeldToken() async {
        await InjectedEnvironment().run {
            let tokenItem = CommonWalletModel.mockETH.tokenItem
            let deeplink = StakingDeeplink(
                tokenId: tokenItem.id?.lowercased() ?? "",
                networkId: tokenItem.blockchain.networkId.lowercased()
            )

            #expect(deeplink.makeOptions()?.sendInput.walletModel.tokenItem == tokenItem)
        }
    }

    @Test("A staking link for a token the wallet doesn't hold has nothing to open, so it goes down the chain")
    func stakingForMissingTokenOpensNothing() async {
        await InjectedEnvironment().run {
            let deeplink = StakingDeeplink(tokenId: "no such token", networkId: "no such network")

            #expect(deeplink.makeOptions() == nil)
        }
    }

    @Test("A yield link for a token without Yield mode finds no target, which is what lands it on the Earn list")
    func yieldForTokenWithoutYieldModeFindsNoTarget() async {
        await InjectedEnvironment().run {
            let tokenItem = CommonWalletModel.mockETH.tokenItem
            let deeplink = YieldDeeplink(
                tokenId: tokenItem.id?.lowercased(),
                networkId: tokenItem.blockchain.networkId.lowercased()
            )

            #expect(deeplink.findTarget() == nil)
        }
    }
}

// MARK: - Observables

private extension TangemPayOnboardingSource {
    var isOther: Bool {
        if case .other = self {
            return true
        }

        return false
    }
}

// MARK: - Constants

private extension DeeplinkNavigationTests {
    enum Constants {
        static let transactionId = "0e0d1c3f"
    }
}
