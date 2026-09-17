//
//  DeeplinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

struct DeeplinkParserTests {
    private let parser = DeeplinkParser()

    // MARK: - Test deeplinks with percent encoding

    @Test("Parses deep link with percent-encoded parameters")
    func parsesPercentEncodedParams() {
        let urlString = "tangem://token?type=income_transaction&name=new%5Fstaking&token_id=bitcoin&network_id=bitcoin&user_wallet_id=7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00&derivation_path=m%5C44%27%5C501%27%5C0%27&transaction_id=9244b376-123b-438b-ab2a-726bc9581d9b"

        guard let url = URL(string: urlString) else {
            #expect(Bool(false), "URL is invalid")
            return
        }

        let result = parser.parse(url)

        // `income_transaction` is not a status update, so the transaction id is not carried over.
        #expect(
            result == .navigation(
                .token(
                    TokenDeeplink(
                        tokenId: "bitcoin",
                        networkId: "bitcoin",
                        userWalletId: "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00",
                        derivationPath: #"m\44'\501'\0'"#
                    )
                )
            )
        )
    }

    @Test("Parses deep link with plain (non-encoded) parameters")
    func parsesPlainParams() {
        let rawURL = "tangem://token?" +
            "type=income_transaction&" +
            "name=new_staking&" +
            "token_id=bitcoin&" +
            "network_id=bitcoin&" +
            "user_wallet_id=7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00&" +
            "derivation_path=m\\44'\\501'\\0'&" +
            "transaction_id=9244b376-123b-438b-ab2a-726bc9581d9b"

        guard let url = URL(string: rawURL) else {
            #expect(Bool(false), "URL is invalid")
            return
        }

        let result = parser.parse(url)

        #expect(
            result == .navigation(
                .token(
                    TokenDeeplink(
                        tokenId: "bitcoin",
                        networkId: "bitcoin",
                        userWalletId: "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00",
                        derivationPath: #"m\44'\501'\0'"#
                    )
                )
            )
        )
    }

    // MARK: - Tests for valid host

    @Test(
        "Parses every host of the tangem scheme with the minimum it needs",
        arguments: [
            "tangem://token?type=income_transaction&token_id=dummy&network_id=dummy",
            "tangem://staking?token_id=dummy&network_id=dummy",
            "tangem://yield?token_id=dummy&network_id=dummy",
            "tangem://swap",
            "tangem://markets",
            "tangem://buy?user_wallet_id=dummy",
            "tangem://sell?user_wallet_id=dummy",
            "tangem://referral?user_wallet_id=dummy",
            "tangem://promo?promo_code=TANGEM",
            "tangem://earn",
            "tangem://pay-account",
            "tangem://token_chart?token_id=dummy",
            "tangem://token_exchanges?token_id=dummy",
            "tangem://survey?token=ntt-abc123",
            "tangem://campaigns?campaignId=some-id",
            "tangem://onboard-visa?entry=some-entry&id=some-id",
            "tangem://joint-account-invite?id=some-invite-id",
            "tangem://pay-app?id=some-id",
            "tangem://news?news_id=190801",
            "tangem://support",
        ]
    )
    func parsesSupportedHost(deeplink: String) throws {
        let url = try #require(URL(string: deeplink))

        #expect(parser.parse(url) != nil, "Expected '\(deeplink)' to be parsed")
    }

    /// An article is named by a path, never by a host, and a news id that isn't a number is no id at all.
    @Test("Rejects links no destination answers to", arguments: ["tangem://news?news_id=not-a-number", "tangem://news-article?id=190801"])
    func rejectsLinksNoDestinationAnswers(deeplink: String) throws {
        let url = try #require(URL(string: deeplink))

        #expect(parser.parse(url) == nil)
    }

    @Test("Parses campaigns deeplink without campaignId")
    func parsesCampaignsDeeplinkWithoutCampaignId() throws {
        let url = try #require(URL(string: "tangem://campaigns"))
        let result = parser.parse(url)

        #expect(result == .navigation(.campaigns(CampaignsDeeplink(campaignId: nil))))
    }

    @Test("Extracts campaignId from a campaigns deeplink")
    func extractsCampaignIdFromCampaignsDeeplink() throws {
        let url = try #require(URL(string: "tangem://campaigns?campaignId=whale-swap-cashback"))
        let result = parser.parse(url)

        #expect(result == .navigation(.campaigns(CampaignsDeeplink(campaignId: "whale-swap-cashback"))))
    }

    @Test(
        "Rejects deeplink with unknown host",
        arguments: [
            URL(string: "tangem://unknown?token_id=eth&network_id=ethereum")!,
            URL(string: "tangem://main")!,
        ]
    )
    func rejectsUnknownHost(url: URL) {
        let result = parser.parse(url)
        #expect(result == nil, "Expected unknown host to be rejected")
    }

    // MARK: - Token host tests

    @Test("Parses valid token deeplink with full parameters")
    func parsesTokenDeeplink() {
        let url = URL(string: "tangem://token?type=income_transaction&name=ETH&token_id=ethereum&network_id=ethereum")!
        let result = parser.parse(url)

        #expect(result == .navigation(.token(TokenDeeplink(tokenId: "ethereum", networkId: "ethereum"))))
    }

    // MARK: - External Links Test

    @Test("The pay-app page names a destination even though it arrives as a path")
    func parsesPayAppPage() throws {
        let url = try #require(URL(string: "https://tangem.com/pay-app?id=something"))

        #expect(parser.parse(url) == .navigation(.payApp(PayAppDeeplink(deeplinkString: url.absoluteString))))
    }

    /// Pages that name no destination are none of this parser's business — `ExternalLinkParser` has the last
    /// word on them, which `ExternalLinkParsingTests` covers.
    @Test(
        "A page that names no destination is left alone",
        arguments: [
            URL(string: "https://tangem.com/some/page")!,
            URL(string: "https://buy.tangem.com/?promocode=PROMO")!,
            URL(string: "https://tangem.com/joint-account")!,
        ]
    )
    func leavesPlainPagesAlone(url: URL) {
        #expect(parser.parse(url) == nil)
    }

    /// A page that names a destination but doesn't carry what it needs is not navigation either — it stays
    /// the page it is, which `ExternalLinkParsingTests` covers.
    @Test("A page that names a destination without what it needs is left alone")
    func leavesIncompletePagesAlone() throws {
        let url = try #require(URL(string: "https://tangem.com/pay-app"))

        #expect(parser.parse(url) == nil)
    }

    @Test(
        "Reject invalid external links from Tangem domains",
        arguments: [
            URL(string: "https://tangeem.com/some/page")!, // typo in domain
            URL(string: "https://app.google.com/anything")!, // wrong domain
            URL(string: "http://tangem.com")!, // wrong scheme (http instead of https)
            URL(string: "https://tangem.co/wallet")!, // phishing-style domain
            URL(string: "https://apptangem.com/page")!, // merged domain, not subdomain
            URL(string: "https://wallet.tangem.com/redirect")!, // unlisted subdomain
            URL(string: "https://app.tangem.org/ndef")!, // wrong TLD
            URL(string: "ftp://tangem.com/file")!, // wrong protocol
        ]
    )
    func parsesInvalidExternalLinks(url: URL) {
        let result = parser.parse(url)
        #expect(result == nil, "Expected \(url) NOT to be parsed")
    }

    // MARK: - Missing Params Tests

    @Test("Rejects tangem://token_chart links with missing token id")
    func rejectsTokenCharWithoutTokenId() {
        let url = URL(string: "tangem://token_chart?token_id=")!
        let result = parser.parse(url)

        #expect(result == nil)
    }

    @Test("Rejects tangem://token_chart links with a quoted token id")
    func rejectsTokenChartWithQuotedTokenId() {
        let url = URL(string: "tangem://token_chart?token_id=\"\"")!
        let result = parser.parse(url)

        #expect(result == nil)
    }

    @Test("Rejects tangem://token links with invalid tokenId")
    func rejectsTokenCharWitInvalidTokenId() {
        let url = URL(string: "tangem://token?token_id=invalid!chars&network_id=ethereum")!
        let result = parser.parse(url)

        #expect(result == nil)
    }

    @Test("Rejects tangem:// links with missing host")
    func rejectsNoHost() {
        let url = URL(string: "tangem://")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected empty-host deeplink to be rejected")
    }

    @Test("Rejects tangem://token with invalid or missing params")
    func rejectsInvalidParams() {
        let url = URL(string: "tangem://token")! // Missing query
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing params")
    }

    @Test("Rejects tangem://token with missing tokenId")
    func rejectsTokenWithoutTokenId() {
        let url = URL(string: "tangem://token?network_id=ethereum")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing tokenId")
    }

    @Test("Rejects tangem://token with missing networkId")
    func rejectsTokenWithoutNetworkId() {
        let url = URL(string: "tangem://token?token_id=eth")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing networkId")
    }

    @Test("Rejects tangem://staking with missing networkId")
    func rejectsStakingWithoutNetworkId() {
        let url = URL(string: "tangem://staking?token_id=matic")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing networkId")
    }

    @Test("Parses tangem://yield with required params")
    func parsesYieldWithRequiredParams() {
        let url = URL(string: "tangem://yield?token_id=usd-coin&network_id=base")!
        let result = parser.parse(url)

        #expect(result == .navigation(.yield(YieldDeeplink(tokenId: "usd-coin", networkId: "base"))))
    }

    @Test("Parses tangem://yield with only networkId (falls back to Earn at routing)")
    func parsesYieldWithoutTokenId() {
        let url = URL(string: "tangem://yield?network_id=base")!
        let result = parser.parse(url)

        #expect(result == .navigation(.yield(YieldDeeplink(networkId: "base"))))
    }

    @Test("Parses tangem://yield with only tokenId (falls back to Earn at routing)")
    func parsesYieldWithoutNetworkId() {
        let url = URL(string: "tangem://yield?token_id=usd-coin")!
        let result = parser.parse(url)

        #expect(result == .navigation(.yield(YieldDeeplink(tokenId: "usd-coin"))))
    }

    @Test("Parses empty tangem://yield (falls back to Earn at routing)")
    func parsesEmptyYield() {
        let url = URL(string: "tangem://yield")!
        let result = parser.parse(url)

        #expect(result == .navigation(.yield(YieldDeeplink())))
    }

    @Test("Ignores unknown query params on a valid tangem://yield link")
    func parsesYieldWithUnknownParams() {
        let url = URL(string: "tangem://yield?token_id=usd-coin&network_id=base&foo=bar")!
        let result = parser.parse(url)

        #expect(result == .navigation(.yield(YieldDeeplink(tokenId: "usd-coin", networkId: "base"))))
    }

    @Test("Rejects tangem://yield with malformed characters")
    func rejectsYieldWithInvalidChars() {
        let url = URL(string: "tangem://yield?token_id=usd-coin&network_id=ba$e")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to malformed network_id")
    }

    /// The link reported in [REDACTED_INFO]: a garbage FROM side and amount alongside a valid TO side. It must
    /// still become an incoming action — the routing layer ignores what it can't use and opens the default
    /// swap, whereas rejecting the link here left the user on Main.
    @Test("Parses tangem://swap with unusable FROM side and amount")
    func parsesSwapWithUnusableParams() throws {
        let url = try #require(
            URL(string: "tangem://swap?from_token_id=???&from_network_id=does%20not%20exist&to_token_id=ethereum&to_network_id=ethereum&from_amount=abc")
        )
        let result = parser.parse(url)

        #expect(
            result == .navigation(
                .swap(
                    SwapDeeplink(
                        fromTokenId: "???",
                        fromNetworkId: "does not exist",
                        toTokenId: "ethereum",
                        toNetworkId: "ethereum",
                        fromAmount: "abc"
                    )
                )
            )
        )
    }

    @Test("Parses tangem://survey with required token")
    func parsesSurveyWithToken() throws {
        let url = try #require(URL(string: "tangem://survey?token=ntt-abc123"))
        let result = parser.parse(url)

        #expect(result == .navigation(.survey(SurveyDeeplink(token: "ntt-abc123"))))
    }

    @Test("Rejects tangem://survey with missing token")
    func rejectsSurveyWithoutToken() throws {
        let url = try #require(URL(string: "tangem://survey"))
        let result = parser.parse(url)
        #expect(result == nil)
    }

    @Test("Rejects tangem://token_chart with missing tokenId")
    func rejectsTokenChartWithoutTokenId() {
        let url = URL(string: "tangem://token_chart")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing tokenId")
    }

    // MARK: - Pay account host

    @Test("Parses tangem://pay-account without params")
    func parsesPayAccountWithoutParams() throws {
        let url = try #require(URL(string: "tangem://pay-account"))
        let result = parser.parse(url)

        #expect(result == .navigation(.tangemPayAccount(TangemPayAccountDeeplink(screen: nil, userWalletId: nil))))
    }

    @Test(
        "Parses tangem://pay-account screen param",
        arguments: [
            "add_funds",
            "va_onramp",
            "va_onramp_details",
            "select_plan",
            "current_plan",
            "change_plan",
            "cashback",
            "order_card",
        ]
    )
    func parsesPayAccountScreen(screen: String) throws {
        let url = try #require(URL(string: "tangem://pay-account?screen=\(screen)"))
        let result = parser.parse(url)

        #expect(result == .navigation(.tangemPayAccount(TangemPayAccountDeeplink(screen: screen, userWalletId: nil))))
    }

    @Test("Lower-cases the pay-account screen query value")
    func lowercasesPayAccountScreen() throws {
        let url = try #require(URL(string: "tangem://pay-account?screen=ADD_FUNDS"))
        let result = parser.parse(url)

        #expect(result == .navigation(.tangemPayAccount(TangemPayAccountDeeplink(screen: "add_funds", userWalletId: nil))))
    }

    @Test("Parses tangem://pay-account with user_wallet_id")
    func parsesPayAccountWithUserWalletId() throws {
        let url = try #require(URL(string: "tangem://pay-account?screen=cashback&user_wallet_id=7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00"))
        let result = parser.parse(url)

        #expect(
            result == .navigation(
                .tangemPayAccount(
                    TangemPayAccountDeeplink(screen: "cashback", userWalletId: "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00")
                )
            )
        )
    }

    @Test("Accepts tangem://pay-account with an unknown screen value (falls back to the main screen at routing)")
    func acceptsPayAccountWithUnknownScreen() throws {
        let url = try #require(URL(string: "tangem://pay-account?screen=nonexistent"))
        let result = parser.parse(url)

        #expect(result == .navigation(.tangemPayAccount(TangemPayAccountDeeplink(screen: "nonexistent", userWalletId: nil))))
    }

    @Test(
        "Maps pay-account screen values to incoming actions",
        arguments: [
            ("add_funds", TangemPayOpeningAction.addFunds),
            ("current_plan", TangemPayOpeningAction.currentPlan),
            ("change_plan", TangemPayOpeningAction.changePlan),
            ("order_card", TangemPayOpeningAction.orderCard),
            ("cashback", TangemPayOpeningAction.cashback),
            ("va_onramp", TangemPayOpeningAction.vaOnramp),
            ("va_onramp_details", TangemPayOpeningAction.vaOnrampDetails),
            ("select_plan", TangemPayOpeningAction.selectPlan),
        ]
    )
    func mapsPayAccountScreenToIncomingAction(screen: String, expected: TangemPayOpeningAction) throws {
        let url = try #require(URL(string: "tangem://pay-account?screen=\(screen)"))
        let result = parser.parse(url)

        guard case .navigation(.tangemPayAccount(let deeplink)) = result else {
            #expect(Bool(false), "Expected a pay-account action for \(url)")
            return
        }

        #expect(deeplink.screen.flatMap(TangemPayOpeningAction.init(rawValue:)) == expected)
    }

    @Test(
        "Rejects tangem://pay-account with malformed characters",
        arguments: [
            "tangem://pay-account?screen=add$funds",
            "tangem://pay-account?screen=cashback&user_wallet_id=7AFC37%23",
        ]
    )
    func rejectsPayAccountWithInvalidChars(deeplink: String) throws {
        let url = try #require(URL(string: deeplink))
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected")
    }

    // MARK: - Markets host: order/interval tests

    @Test("Parses tangem://markets with order and interval")
    func parsesMarketsWithOrderAndInterval() {
        let url = URL(string: "tangem://markets?order=trending&interval=1w")!
        let result = parser.parse(url)

        #expect(result == .navigation(.markets(MarketsDeeplink(order: "trending", interval: "1w"))))
    }

    @Test("Parses tangem://markets with only interval (order omitted)")
    func parsesMarketsWithOnlyInterval() {
        let url = URL(string: "tangem://markets?interval=30d")!
        let result = parser.parse(url)

        #expect(result == .navigation(.markets(MarketsDeeplink(order: nil, interval: "30d"))))
    }

    @Test("Parses tangem://markets with only order (interval omitted)")
    func parsesMarketsWithOnlyOrder() {
        let url = URL(string: "tangem://markets?order=gainers")!
        let result = parser.parse(url)

        #expect(result == .navigation(.markets(MarketsDeeplink(order: "gainers", interval: nil))))
    }

    @Test("Lower-cases markets order/interval query values")
    func lowercasesMarketsOrderAndInterval() {
        let url = URL(string: "tangem://markets?order=TRENDING&interval=24H")!
        let result = parser.parse(url)

        #expect(result == .navigation(.markets(MarketsDeeplink(order: "trending", interval: "24h"))))
    }

    @Test("Parses tangem://markets with no query params")
    func parsesMarketsWithoutParams() {
        let url = URL(string: "tangem://markets")!
        let result = parser.parse(url)

        #expect(result == .navigation(.markets(MarketsDeeplink(order: nil, interval: nil))))
    }

    @Test(
        "Accepts tangem://markets even with unknown order/interval values (validation is deferred to routing)",
        arguments: [
            "tangem://markets?order=unknown_sort&interval=1w",
            "tangem://markets?order=rating&interval=5y",
            "tangem://markets?order=bogus&interval=bogus",
        ]
    )
    func acceptsMarketsWithUnknownValues(deeplink: String) {
        let url = URL(string: deeplink)!
        let result = parser.parse(url)

        #expect(result != nil, "Parser should pass unknown values through to routing layer for fallback")
    }
}
