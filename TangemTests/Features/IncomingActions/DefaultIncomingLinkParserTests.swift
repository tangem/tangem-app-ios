//
//  DefaultIncomingLinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

struct DefaultIncomingLinkParserTests {
    private let parser = DefaultIncomingLinkParser()

    // MARK: - Tests for valid type param

    @Test(
        "Parses known valid deeplink kind",
        arguments: [
            "tangem://buy?type=income_transaction",
            "tangem://swap?type=onramp_status_update",
            "tangem://buy?type=swap_status_update",
        ]
    )
    func parseSupportedType(deeplink: String) {
        guard let url = URL(string: deeplink) else {
            #expect(Bool(false), "Invalid URL: \(deeplink)")
            return
        }

        let result = parser.parse(url)
        #expect(result != nil, "Expected deeplink '\(deeplink)' to be parsed")
    }

    // MARK: - Test deeplinks with percent encoding

    @Test("Parses deep link with percent-encoded parameters")
    func parsesPercentEncodedParams() {
        let urlString = "tangem://token?type=income_transaction&name=new%5Fstaking&token_id=bitcoin&network_id=bitcoin&user_wallet_id=7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00&derivation_path=m%5C44%27%5C501%27%5C0%27&transaction_id=9244b376-123b-438b-ab2a-726bc9581d9b"

        guard let url = URL(string: urlString) else {
            #expect(Bool(false), "URL is invalid")
            return
        }

        let result = parser.parse(url)
        #expect(result != nil, "Expected parser to handle percent-encoded parameters")

        if case .navigation(let action) = result {
            let params = action.params

            #expect(params.type == .incomeTransaction)
            #expect(params.name == "new_staking")
            #expect(params.tokenId == "bitcoin")
            #expect(params.networkId == "bitcoin")
            #expect(params.userWalletId == "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00")
            #expect(params.derivationPath == #"m\44'\501'\0'"#)
            #expect(params.transactionId == "9244b376-123b-438b-ab2a-726bc9581d9b")
        } else {
            #expect(Bool(false), "Expected IncomingAction.navigation for \(url)")
        }
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
        #expect(result != nil, "Expected parser to handle plain parameters")

        if case .navigation(let action) = result {
            let params = action.params

            #expect(params.type == .incomeTransaction)
            #expect(params.name == "new_staking")
            #expect(params.tokenId == "bitcoin")
            #expect(params.networkId == "bitcoin")
            #expect(params.userWalletId == "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00")
            #expect(params.derivationPath == #"m\44'\501'\0'"#)
            #expect(params.transactionId == "9244b376-123b-438b-ab2a-726bc9581d9b")
        } else {
            #expect(Bool(false), "Expected IncomingAction.navigation for \(url)")
        }
    }

    // MARK: - Tests for valid host

    @Test("Parses all known hosts with minimal valid params", arguments: IncomingActionConstants.DeeplinkDestination.allCases)
    func parsesSupportedHost(host: IncomingActionConstants.DeeplinkDestination) {
        let rawValue = host.rawValue

        let urlString: String
        switch host {
        case .token, .staking:
            urlString = "tangem://\(rawValue)?type=income_transaction&token_id=dummy&network_id=dummy"
        case .tokenChart:
            urlString = "tangem://\(rawValue)?type=income_transaction&token_id=dummy"
        case .onboardVisa:
            urlString = "tangem://\(rawValue)?entry=some-entry&id=some-id"
        case .payApp:
            urlString = "https://tangem.com/\(rawValue)?id=some-id"
        case .news:
            urlString = "tangem://\(rawValue)?id=some-id"
        default:
            urlString = "tangem://\(rawValue)?type=income_transaction"
        }

        guard let url = URL(string: urlString) else {
            #expect(Bool(false), "Invalid URL for host: \(host)")
            return
        }

        let result = parser.parse(url)
        #expect(result != nil, "Expected host '\(host)' to be parsed successfully")
    }

    @Test(
        "Rejects deeplink with unknown host",
        arguments: [
            URL(string: "tangem://unknown?token_id=eth&network_id=ethereum")!,
            URL(string: "tangem://main")!
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

        #expect(result != nil)
        if case .navigation(let action) = result {
            #expect(action.destination == .token)
            #expect(action.params.tokenId == "ethereum")
            #expect(action.params.networkId == "ethereum")
            #expect(action.params.type?.rawValue == "income_transaction")
            #expect(action.params.name == "ETH")
        } else {
            #expect(Bool(false), "Expected navigation action for token deeplink")
        }
    }

    // MARK: - External Links Test

    @Test(
        "Parses valid external links from Tangem domains",
        arguments: [
            URL(string: "https://tangem.com/some/page")!,
            URL(string: "https://app.tangem.com/anything")!,
            URL(string: "https://tangem.com/pay-app?id=something")!,
        ]
    )
    func parsesExternalLinks(url: URL) {
        let result = parser.parse(url)
        #expect(result != nil, "Expected \(url) to be parsed")

        switch result {
        case .navigation(let action) where action.destination == .link:
            #expect(url == action.params.url)

        case .navigation(let action) where action.destination == .payApp:
            #expect("something" == action.params.id)

        default:
            #expect(Bool(false), "Expected IncomingAction.navigation for \(url)")
        }
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
            URL(string: "https://tangem.com/pay-app")!, // missing id query param
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

    @Test("Rejects tangem://token_chart links with empty token id")
    func rejectsTokenCharWitEmptytTokenId() {
        let url = URL(string: "tangem://token_chart?token_id=\"\"")!
        let result = parser.parse(url)

        #expect(result == nil)
    }

    @Test("Rejects tangem://token links with invalid tokenId")
    func rejectsTokenCharWitInvalidTokenId() {
        let url = URL(string: "tangem://token?token_id=ываываыа&network_id=ethereum")!
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

    @Test("Rejects tangem://token_chart with missing tokenId")
    func rejectsTokenChartWithoutTokenId() {
        let url = URL(string: "tangem://token_chart")!
        let result = parser.parse(url)

        #expect(result == nil, "Expected \(url) to be rejected due to missing tokenId")
    }
}
