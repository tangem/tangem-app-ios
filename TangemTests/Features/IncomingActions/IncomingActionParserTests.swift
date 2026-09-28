//
//  IncomingActionParserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// A scheme is case-insensitive, so the app is opened by a link typed with a capital in it — by hand, in a
/// note, in a campaign — exactly as by one written the way we publish them. This is where the two meet: past
/// this parser every link is read in lower case.
@Suite("Reading an incoming link")
struct IncomingActionParserTests {
    private let parser = IncomingActionParser()

    @Test(
        "A deeplink names the same destination however its scheme is written",
        arguments: [
            "tangem://markets",
            "Tangem://markets",
            "TANGEM://markets",
        ]
    )
    func appSchemeCase(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == .navigation(.markets(MarketsDeeplink(order: nil, interval: nil))))
    }

    @Test(
        "A page of ours names the same destination however its scheme is written",
        arguments: [
            "https://tangem.com/pay-app?id=some-id",
            "HTTPS://tangem.com/pay-app?id=some-id",
        ]
    )
    func webSchemeCase(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) != nil)
    }

    /// Our own scheme is not a blockchain one whatever case it is written in. Reading it as one is worse than
    /// reading nothing: the link would ask for a card scan instead of the screen it names.
    @Test("A push carrying a link under the deeplink key is read as that link")
    func pushWithDeeplinkKey() {
        let action = parser.parse(push: ["deeplink": "tangem://markets"])

        #expect(action == .navigation(.markets(MarketsDeeplink(order: nil, interval: nil))))
    }

    @Test("A push carrying a page of ours under the link key opens it as a page")
    func pushWithLinkKey() throws {
        let action = parser.parse(push: ["link": "https://tangem.com/blog"])

        #expect(action == .externalLink(try #require(URL(string: "https://tangem.com/blog"))))
    }

    @Test("A transaction push is read as a link to the token it is about")
    func transactionPush() throws {
        let action = parser.parse(push: [
            "type": "income_transaction",
            "network_id": "ethereum",
            "token_id": "ethereum",
            "user_wallet_id": Constants.walletId,
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.tokenId == "ethereum")
        #expect(deeplink.userWalletId == Constants.walletId)
        #expect(deeplink.statusUpdate == nil)
    }

    @Test("A status push carries its transaction into the token link")
    func statusPushCarriesItsTransaction() {
        let action = parser.parse(push: [
            "type": "onramp_status_update",
            "network_id": "ethereum",
            "token_id": "ethereum",
            "user_wallet_id": Constants.walletId,
            "derivation_path": "m/44'/60'/0'/0/0",
            "transaction_id": Constants.transactionId,
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.statusUpdate == TokenDeeplink.StatusUpdate(kind: .onramp, transactionId: Constants.transactionId))
    }

    @Test("A status push without its transaction has nothing to open")
    func statusPushWithoutTransactionIsNotAnAction() {
        let action = parser.parse(push: [
            "type": "swap_status_update",
            "network_id": "ethereum",
            "token_id": "ethereum",
            "user_wallet_id": Constants.walletId,
            "derivation_path": "m/44'/60'/0'/0/0",
            "transaction_id": "null",
        ])

        #expect(action == nil)
    }

    @Test("A joint sent push is read as a link to the token of the account it names")
    func jointSentPushNamesItsAccount() {
        let action = parser.parse(push: [
            "type": "joint_tx_sent",
            "network_id": "polygon-pos",
            "token_id": "polygon-ecosystem-token",
            "user_wallet_id": Constants.walletId,
            "account_id": Constants.accountId,
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.accountId == Constants.accountId.lowercased())
        #expect(deeplink.statusUpdate == nil)
    }

    @Test("A transaction push naming an account is not taken for a joint one")
    func transactionPushWithAccountIsNotJoint() {
        let action = parser.parse(push: [
            "type": "income_transaction",
            "network_id": "polygon-pos",
            "token_id": "polygon-ecosystem-token",
            "user_wallet_id": Constants.walletId,
            "account_id": Constants.accountId,
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.accountId == Constants.accountId.lowercased())
        #expect(!deeplink.isJointTransaction)
    }

    @Test("A joint sent push whose account is \"null\" names no account, yet stays a joint link")
    func jointSentPushWithNullAccount() {
        let action = parser.parse(push: [
            "type": "joint_tx_sent",
            "network_id": "polygon-pos",
            "token_id": "polygon-ecosystem-token",
            "user_wallet_id": Constants.walletId,
            "account_id": "null",
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.accountId == nil)
        #expect(deeplink.isJointTransaction)
    }

    @Test("A joint operation push points at its operation without a derivation")
    func jointOperationPushCarriesItsOperation() {
        let action = parser.parse(push: [
            "type": "joint_tx",
            "network_id": "polygon-pos",
            "token_id": "polygon-ecosystem-token",
            "user_wallet_id": Constants.walletId,
            "transaction_id": Constants.transactionId,
        ])

        guard case .navigation(.token(let deeplink)) = action else {
            Issue.record("Expected a token link, got \(String(describing: action))")
            return
        }

        #expect(deeplink.statusUpdate == TokenDeeplink.StatusUpdate(kind: .jointOperation, transactionId: Constants.transactionId))
    }

    @Test(
        "A joint account push is read as the screen of the account it names",
        arguments: [
            ("joint_members", JointAccountDeeplink.Entry.members),
            ("joint_overview", JointAccountDeeplink.Entry.overview),
        ]
    )
    func jointAccountPush(type: String, entry: JointAccountDeeplink.Entry) {
        let action = parser.parse(push: [
            "type": type,
            "user_wallet_id": Constants.walletId,
            "account_id": Constants.accountId,
        ])

        #expect(action == .navigation(.jointAccount(
            JointAccountDeeplink(entry: entry, userWalletId: Constants.walletId, accountId: Constants.accountId.lowercased())
        )))
    }

    @Test("A joint account push without its account has nothing to open")
    func jointAccountPushWithoutAccountIsNotAnAction() {
        let action = parser.parse(push: [
            "type": "joint_members",
            "user_wallet_id": Constants.walletId,
            "account_id": "null",
        ])

        #expect(action == nil)
    }

    @Test("A payment push is read as the screen it asks for")
    func paymentPush() {
        let action = parser.parse(push: [
            "type": "card_ready",
            "customer_wallet_id": Constants.walletId,
            "customer_id": "32080398-6b36-4cd5-af29-bfe18cfa30d5",
        ])

        #expect(action == .navigation(.tangemPayAccount(TangemPayAccountDeeplink(screen: nil, userWalletId: Constants.walletId))))
    }

    @Test("A push carrying none of what we read is not an action")
    func unknownPush() {
        #expect(parser.parse(push: ["aps": ["alert": "Hello"]]) == nil)
    }

    @Test("An app link written in capitals is not taken for a blockchain link")
    func appSchemeInCapitalsIsNotABlockchainLink() throws {
        let url = try #require(URL(string: "TANGEM://markets"))

        #expect(parser.parseIncomingURL(url) != .start)
    }

    /// The link is rebuilt to normalise its scheme, and what it carries has to come out of that exactly as it
    /// went in.
    @Test("What a link carries survives the scheme being normalised")
    func parametersSurviveNormalisation() throws {
        let link = "token?type=income_transaction&token_id=bitcoin&network_id=bitcoin&derivation_path=m%5C44%27%5C501%27%5C0%27&transaction_id=9244b376"
        let published = try #require(URL(string: "tangem://\(link)"))
        let capitalised = try #require(URL(string: "Tangem://\(link)"))

        let action = parser.parseIncomingURL(capitalised)

        #expect(action != nil)
        #expect(action == parser.parseIncomingURL(published))
    }
}

// MARK: - Constants

private extension IncomingActionParserTests {
    enum Constants {
        static let walletId = "7AFC37E5D8BB0C5F29C0D5FD7835A63CC6A87DA00DD8B72BBBDA5C8CF4AACA0E"
        static let transactionId = "9244b376"
        static let accountId = "BA910A77A178F75B"
    }
}
