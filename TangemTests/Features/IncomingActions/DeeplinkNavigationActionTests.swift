//
//  DeeplinkNavigationActionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// What each destination needs from a link to become an action, and what turns the link away.
@Suite("Typed deeplink actions")
struct DeeplinkNavigationActionTests {
    // MARK: - Token chart

    @Test(
        "A token chart link takes any token id of allowed characters",
        arguments: [
            "ethereum",
            "ethereum@",
            "ethereum123",
            "ethereum_123-ethereum",
            "ethereu.ethereum",
            "energy-web-token-123",
        ]
    )
    func tokenChartTokenIds(tokenId: String) {
        #expect(action("tangem://token_chart?token_id=\(tokenId)") == .tokenChart(TokenChartDeeplink(tokenId: tokenId)))
    }

    @Test(
        "A token chart link without a usable token id is turned away",
        arguments: [
            "tangem://token_chart",
            "tangem://token_chart?token_id=",
            "tangem://token_chart?token_id=bad%20token$",
            "tangem://token_chart?token_id=token%23invalid",
        ]
    )
    func tokenChartWithoutUsableTokenId(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Token exchanges

    @Test("A token exchanges link takes the token id")
    func tokenExchanges() {
        #expect(action("tangem://token_exchanges?token_id=ethereum") == .tokenExchanges(TokenExchangesDeeplink(tokenId: "ethereum")))
    }

    @Test(
        "A token exchanges link without a usable token id is turned away",
        arguments: [
            "tangem://token_exchanges",
            "tangem://token_exchanges?token_id=bad%20token$",
            "tangem://token_exchanges?token_id=token%23invalid",
        ]
    )
    func tokenExchangesWithoutUsableTokenId(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Staking

    @Test("A staking link carries the token and its network")
    func staking() {
        #expect(
            action("tangem://staking?token_id=solana&network_id=mainnet-beta")
                == .staking(StakingDeeplink(tokenId: "solana", networkId: "mainnet-beta"))
        )
    }

    /// `@` is an allowed character, so a network id carrying one is a valid link.
    @Test("A staking link accepts an at sign in the network id")
    func stakingWithAtSignInNetworkId() {
        #expect(
            action("tangem://staking?token_id=avalanche&network_id=main@net")
                == .staking(StakingDeeplink(tokenId: "avalanche", networkId: "main@net"))
        )
    }

    @Test(
        "A staking link missing or malforming either side is turned away",
        arguments: [
            "tangem://staking?network_id=mainnet",
            "tangem://staking?token_id=avalanche",
            "tangem://staking?token_id=avala%20nche$&network_id=mainnet",
            "tangem://staking?token_id=token%23invalid&network_id=net%23invalid",
        ]
    )
    func stakingWithIncompleteParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Yield

    /// A yield link needs nothing: whatever can't reach the Yield-mode screen falls back to Earn when handled.
    @Test(
        "A yield link takes whatever it carries",
        arguments: [
            ("tangem://yield?token_id=usd-coin&network_id=base", YieldDeeplink(tokenId: "usd-coin", networkId: "base")),
            ("tangem://yield?network_id=base", YieldDeeplink(networkId: "base")),
            ("tangem://yield?token_id=usd-coin", YieldDeeplink(tokenId: "usd-coin")),
            ("tangem://yield", YieldDeeplink()),
        ]
    )
    func yieldParams(urlString: String, expected: YieldDeeplink) {
        #expect(action(urlString) == .yield(expected))
    }

    @Test(
        "A yield link of malformed values is turned away",
        arguments: [
            "tangem://yield?token_id=usd%20coin$&network_id=base",
            "tangem://yield?token_id=token%23invalid&network_id=net%23invalid",
        ]
    )
    func yieldWithMalformedParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Token

    @Test("A token link carries the token and its network")
    func token() {
        #expect(
            action("tangem://token?token_id=bitcoin&network_id=mainnet")
                == .token(TokenDeeplink(tokenId: "bitcoin", networkId: "mainnet"))
        )
    }

    /// An income transaction opens the token screen itself, so it carries no status update.
    @Test("An income transaction link is a plain token link")
    func tokenWithIncomeTransactionType() {
        #expect(
            action("tangem://token?type=income_transaction&token_id=sol&network_id=solnet")
                == .token(TokenDeeplink(tokenId: "sol", networkId: "solnet"))
        )
    }

    @Test(
        "A status update link carries the transaction it points at",
        arguments: [
            ("onramp_status_update", TokenDeeplink.StatusUpdate.Kind.onramp),
            ("swap_status_update", TokenDeeplink.StatusUpdate.Kind.swap),
            ("joint_tx", TokenDeeplink.StatusUpdate.Kind.jointOperation),
        ]
    )
    func tokenWithStatusUpdate(type: String, kind: TokenDeeplink.StatusUpdate.Kind) {
        let urlString = "tangem://token?type=\(type)&token_id=btc&network_id=btc-main&derivation_path=m/44'/0'/0'&transaction_id=tx123abc"

        #expect(
            action(urlString)
                == .token(
                    TokenDeeplink(
                        tokenId: "btc",
                        networkId: "btc-main",
                        derivationPath: "m/44'/0'/0'",
                        isJointTransaction: kind == .jointOperation,
                        statusUpdate: .init(kind: kind, transactionId: "tx123abc")
                    )
                )
        )
    }

    @Test("A joint operation link names its account instead of a derivation")
    func tokenWithJointOperation() {
        #expect(
            action("tangem://token?type=joint_tx&token_id=pol&network_id=polygon-pos&account_id=BA910A77&transaction_id=tx123abc")
                == .token(
                    TokenDeeplink(
                        tokenId: "pol",
                        networkId: "polygon-pos",
                        accountId: "ba910a77",
                        isJointTransaction: true,
                        statusUpdate: .init(kind: .jointOperation, transactionId: "tx123abc")
                    )
                )
        )
    }

    @Test(
        "A joint account link opens the screen of the account it names",
        arguments: [
            ("members", JointAccountDeeplink.Entry.members),
            ("overview", JointAccountDeeplink.Entry.overview),
        ]
    )
    func jointAccount(entry: String, expected: JointAccountDeeplink.Entry) {
        #expect(
            action("tangem://joint_account?entry=\(entry)&user_wallet_id=AB12&account_id=BA910A77")
                == .jointAccount(JointAccountDeeplink(entry: expected, userWalletId: "AB12", accountId: "ba910a77"))
        )
    }

    @Test(
        "A joint account link missing what it needs is turned away",
        arguments: [
            "tangem://joint_account?user_wallet_id=AB12&account_id=BA910A77",
            "tangem://joint_account?entry=settings&user_wallet_id=AB12&account_id=BA910A77",
            "tangem://joint_account?entry=members&account_id=BA910A77",
            "tangem://joint_account?entry=members&user_wallet_id=AB12",
        ]
    )
    func jointAccountWithIncompleteParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    @Test(
        "A token link missing what its type needs is turned away",
        arguments: [
            "tangem://token?network_id=mainnet",
            "tangem://token?token_id=bitcoin",
            "tangem://token?token_id=bad%20token$&network_id=mainnet",
            // A status update without the transaction it points at, or without the address it happened on
            "tangem://token?type=onramp_status_update&token_id=btc&network_id=btc-net&derivation_path=m/44'/0'/0'",
            "tangem://token?type=swap_status_update&token_id=dot&network_id=dotnet&transaction_id=tx-001",
            "tangem://token?type=onramp_status_update&token_id=%F0%9F%94%A5btc&network_id=btc-main&derivation_path=m/44'/0'/0'&transaction_id=tx123",
        ]
    )
    func tokenWithIncompleteParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Wallet-scoped destinations

    /// These name no token of their own, yet a malformed one alongside them still turns the link away.
    @Test(
        "A wallet-scoped link is turned away by a malformed token id it doesn't even read",
        arguments: [
            "buy",
            "sell",
            "referral",
            "markets",
            "promo",
        ]
    )
    func walletScopedDestinationsWithMalformedTokenId(host: String) {
        let urlString = "tangem://\(host)?promo_code=TANGEM&token_id=%F0%9F%94%A5&network_id=net"

        #expect(action(urlString) == nil)
    }

    @Test(
        "A wallet-scoped link keeps its wallet id",
        arguments: [
            ("buy", DeeplinkNavigationAction.buy(BuyDeeplink(userWalletId: "wallet-1"))),
            ("sell", .sell(SellDeeplink(userWalletId: "wallet-1"))),
            ("referral", .referral(ReferralDeeplink(userWalletId: "wallet-1"))),
        ]
    )
    func walletScopedDestinations(host: String, expected: DeeplinkNavigationAction) {
        #expect(action("tangem://\(host)?user_wallet_id=wallet-1") == expected)
    }

    // MARK: - Promo

    @Test("A promo link carries the code and where it came from")
    func promo() {
        #expect(
            action("tangem://promo?promo_code=TANGEM&ref=friend&campaign=summer")
                == .promo(PromoDeeplink(code: "TANGEM", refcode: "friend", campaign: "summer"))
        )
    }

    @Test("A promo link naming no one keeps the code and nothing else", arguments: ["null", "%20"])
    func promoWithoutReferral(rawRefcode: String) {
        #expect(
            action("tangem://promo?promo_code=TANGEM&ref=\(rawRefcode)&campaign=\(rawRefcode)")
                == .promo(PromoDeeplink(code: "TANGEM", refcode: nil, campaign: nil))
        )
    }

    /// The code is the whole link — without it there is nothing to activate.
    @Test("A promo link without a code is turned away", arguments: ["tangem://promo", "tangem://promo?ref=friend"])
    func promoWithoutCode(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Swap

    /// No swap parameter can invalidate the link: whatever can't be used is ignored when it is handled,
    /// which opens the default swap instead of leaving the user where they were.
    @Test(
        "A swap link is taken whatever it carries",
        arguments: [
            "tangem://swap",
            "tangem://swap?from_token_id=usd-coin&from_network_id=ethereum&to_token_id=tether&to_network_id=ethereum",
            "tangem://swap?from_token_id=%F0%9F%94%A5",
            "tangem://swap?from_amount=%F0%9F%94%A5",
            "tangem://swap?token_id=%F0%9F%94%A5&from_token_id=usd-coin",
            "tangem://swap?from_token_id=usd-coin&from_network_id=ethereum&from_amount=0.5&provider_id=changelly",
        ]
    )
    func swapIsAlwaysTaken(urlString: String) {
        #expect(action(urlString) != nil)
    }

    /// The link reported in [REDACTED_INFO]: a garbage FROM side and amount next to a well-formed TO side.
    @Test("A swap link with an unusable FROM side keeps everything it carries")
    func swapWithUnusableFromSide() {
        let urlString = "tangem://swap?from_token_id=???&from_network_id=does%20not%20exist&to_token_id=ethereum&to_network_id=ethereum&from_amount=abc"

        #expect(
            action(urlString)
                == .swap(
                    SwapDeeplink(
                        fromTokenId: "???",
                        fromNetworkId: "does not exist",
                        toTokenId: "ethereum",
                        toNetworkId: "ethereum",
                        fromAmount: "abc"
                    )
                )
        )
    }

    // MARK: - Onboard Visa

    @Test("A Visa onboarding link is attributed to itself")
    func onboardVisa() {
        let urlString = "tangem://onboard-visa?entry=some-entry&id=some-id"

        #expect(action(urlString) == .onboardVisa(OnboardVisaDeeplink(deeplinkString: urlString)))
    }

    @Test(
        "A Visa onboarding link missing either side is turned away",
        arguments: [
            "tangem://onboard-visa?entry=some-entry",
            "tangem://onboard-visa?id=some-id",
        ]
    )
    func onboardVisaWithIncompleteParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - News

    @Test(
        "A news link takes numeric ids only",
        arguments: [
            ("tangem://news", DeeplinkNavigationAction.news(NewsDeeplink(newsId: nil, categoryId: nil))),
            ("tangem://news?category_id=12", .news(NewsDeeplink(newsId: nil, categoryId: 12))),
            ("tangem://news?news_id=900", .news(NewsDeeplink(newsId: 900, categoryId: nil))),
        ]
    )
    func news(urlString: String, expected: DeeplinkNavigationAction) {
        #expect(action(urlString) == expected)
    }

    @Test(
        "A news link of non-numeric ids is turned away",
        arguments: [
            "tangem://news?category_id=x",
            "tangem://news?news_id=x",
            "tangem://news?news_id=-5",
        ]
    )
    func newsWithNonNumericIds(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Earn

    @Test(
        "An earn link takes the filter it carries",
        arguments: [
            ("tangem://earn", DeeplinkNavigationAction.earn(EarnDeeplink(earnType: nil, networkId: nil))),
            ("tangem://earn?earn_type=staking&network_id=ethereum", .earn(EarnDeeplink(earnType: "staking", networkId: "ethereum"))),
        ]
    )
    func earn(urlString: String, expected: DeeplinkNavigationAction) {
        #expect(action(urlString) == expected)
    }

    @Test(
        "An earn link of malformed values is turned away",
        arguments: [
            "tangem://earn?earn_type=bad$type&network_id=ethereum",
            "tangem://earn?earn_type=yield&network_id=ethereum!",
        ]
    )
    func earnWithMalformedParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Discover

    @Test(
        "A discover link takes the section and filter it carries",
        arguments: [
            ("tangem://discover", DeeplinkNavigationAction.feed(FeedDeeplink(section: nil, category: nil, type: nil))),
            ("tangem://discover?section=Assets", .feed(FeedDeeplink(section: "assets", category: nil, type: nil))),
            (
                "tangem://discover?section=Assets&category=XStocks&type=Staking",
                .feed(FeedDeeplink(section: "assets", category: "xstocks", type: "staking"))
            ),
            (
                "tangem://discover?section=earn&type=embedded_yield",
                .feed(FeedDeeplink(section: "earn", category: nil, type: "embedded_yield"))
            ),
        ]
    )
    func shtorka(urlString: String, expected: DeeplinkNavigationAction) {
        #expect(action(urlString) == expected)
    }

    // MARK: - Campaigns

    /// A campaign link needs no id: a missing one falls back to the campaign-not-active sheet when handled.
    @Test(
        "A campaigns link takes the id it carries, if any",
        arguments: [
            ("tangem://campaigns?campaignId=whale-swap-cashback", DeeplinkNavigationAction.campaigns(CampaignsDeeplink(campaignId: "whale-swap-cashback"))),
            ("tangem://campaigns", .campaigns(CampaignsDeeplink(campaignId: nil))),
            ("tangem://campaigns?campaignId=", .campaigns(CampaignsDeeplink(campaignId: nil))),
        ]
    )
    func campaigns(urlString: String, expected: DeeplinkNavigationAction) {
        #expect(action(urlString) == expected)
    }

    @Test("A campaigns link of a malformed id is turned away")
    func campaignsWithMalformedId() {
        #expect(action("tangem://campaigns?campaignId=whale%20swap%23cashback") == nil)
    }

    // MARK: - Survey

    /// SurveySparrow tokens are opaque vendor identifiers of no fixed shape, so anything but emptiness goes.
    @Test(
        "A survey link takes the token whatever shape it has",
        arguments: [
            "tt-5xtkamxzdOD",
            "ntt-84iF22PDajmervYneMW4kv",
            "abc+def/ghi=",
            "token with spaces",
        ]
    )
    func surveyTokenShapes(token: String) throws {
        let encoded = try #require(token.addingPercentEncoding(withAllowedCharacters: .alphanumerics))

        #expect(action("tangem://survey?token=\(encoded)") == .survey(SurveyDeeplink(token: token)))
    }

    @Test(
        "A survey link without a token is turned away",
        arguments: [
            "tangem://survey",
            "tangem://survey?token=",
            "tangem://survey?token=%20%20",
        ]
    )
    func surveyWithoutToken(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Pay account

    @Test("A pay account link carries the screen to open and the wallet to open it for")
    func tangemPayAccount() {
        #expect(
            action("tangem://pay-account?screen=cashback&user_wallet_id=wallet-1")
                == .tangemPayAccount(TangemPayAccountDeeplink(screen: "cashback", userWalletId: "wallet-1"))
        )
    }

    @Test(
        "A pay account link of malformed values is turned away",
        arguments: [
            "tangem://pay-account?screen=add$funds",
            "tangem://pay-account?screen=cashback&user_wallet_id=7AFC37%23",
        ]
    )
    func tangemPayAccountWithMalformedParams(urlString: String) {
        #expect(action(urlString) == nil)
    }

    // MARK: - Joint account invite

    @Test("A joint account invite link is the invite id")
    func jointAccountInvite() {
        #expect(action("tangem://joint-account-invite?id=invite-1") == .jointAccountInvite(JointAccountInviteDeeplink(inviteId: "invite-1")))
    }

    @Test("A joint account invite link without an id is turned away")
    func jointAccountInviteWithoutId() {
        #expect(action("tangem://joint-account-invite") == nil)
    }

    // MARK: - Support

    /// The chat is the same conversation whatever the link says, so nothing in it can turn it away — not even
    /// a parameter another destination would have rejected.
    @Test(
        "A support link opens the chat whatever it carries",
        arguments: [
            "tangem://support",
            "tangem://support?user_wallet_id=wallet-1",
            "tangem://support?token_id=bad%20token$",
        ]
    )
    func support(urlString: String) {
        #expect(action(urlString) == .support(SupportDeeplink()))
    }
}

// MARK: - Helpers

private extension DeeplinkNavigationActionTests {
    func action(_ urlString: String) -> DeeplinkNavigationAction? {
        guard let url = URL(string: urlString), let link = DeeplinkURL(url: url) else {
            Issue.record("Not a link of ours: \(urlString)")
            return nil
        }

        return DeeplinkNavigationAction(link: link)
    }
}
