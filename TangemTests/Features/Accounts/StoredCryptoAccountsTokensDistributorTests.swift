//
//  StoredCryptoAccountsTokensDistributorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import enum BlockchainSdk.Blockchain
import struct TangemSdk.DerivationPath
@testable import Tangem

/// A token carries no account of its own — only a derivation path, whose account node names the account it belongs
/// to. The distributor is what holds the two in step.
@Suite("Tests for how `StoredCryptoAccountsTokensDistributor` spreads tokens across accounts")
struct StoredCryptoAccountsTokensDistributorTests {
    // MARK: - Redistribution between the wallet's own accounts

    @Test("A token whose path names another existing account is moved into it")
    func tokenIsMovedIntoTheAccountItsPathNames() throws {
        var accounts = [
            try Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc", at: "m/44'/0'/1'/0/0")]),
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[0].tokens.isEmpty)
        #expect(accounts[1].tokens.map(\.name) == ["btc"])
        #expect(result.isRedistributionHappened)
    }

    @Test("A token already kept where its path names stays, and nothing is reported")
    func tokenInItsOwnAccountStaysPut() throws {
        var accounts = [
            try Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc", at: "m/44'/0'/0'/0/0")]),
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[0].tokens.map(\.name) == ["btc"])
        #expect(accounts[1].tokens.isEmpty)
        #expect(!result.isRedistributionHappened)
    }

    @Test("A token whose path names an account the wallet does not have stays where it is")
    func tokenNamingAMissingAccountStaysPut() throws {
        var accounts = [
            try Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc", at: "m/44'/0'/9'/0/0")]),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[0].tokens.map(\.name) == ["btc"])
        #expect(!result.isRedistributionHappened)
    }

    @Test("A token whose path names no account at all falls back to the Main account")
    func tokenWithAMalformedPathFallsBackToMain() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            // Too few nodes to name an account, which only the Main account can hold
            try Fixtures.account(name: "Savings", index: 1, tokens: [Fixtures.token("btc", at: "m/44'/0'")]),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[0].tokens.map(\.name) == ["btc"])
        #expect(accounts[1].tokens.isEmpty)
        #expect(result.isRedistributionHappened)
    }

    @Test("A token of a network this version cannot place stays where it is")
    func tokenOfAnUnsupportedNetworkStaysPut() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            Fixtures.account(name: "Savings", index: 1, tokens: [Fixtures.unsupportedToken("mystery")]),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[1].tokens.map(\.name) == ["mystery"])
        #expect(!result.isRedistributionHappened)
    }

    @Test("The result names the accounts a token was moved between")
    func resultNamesBothAccounts() throws {
        var accounts = [
            try Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc", at: "m/44'/0'/1'/0/0")]),
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        guard case .redistributionHappened(let pairs) = result else {
            Issue.record("Expected a redistribution to be reported")
            return
        }

        #expect(pairs.count == 1)
        #expect(pairs.first?.source == .account(name: "Main"))
        #expect(pairs.first?.toAccountName == "Savings")
    }

    // MARK: - Joint accounts

    @Test("A joint account is left exactly as it came: nothing is moved out of it, whatever its tokens' paths say")
    func jointAccountIsLeftUntouched() throws {
        let jointTokens = [
            // Names another existing account, and would have been moved had the account been the wallet's own
            try Fixtures.token("btc", at: "m/44'/0'/0'/0/0"),
            // Names no account at all, which for the wallet's own accounts means the Main one
            try Fixtures.token("ltc", at: "m/44'/0'"),
        ]
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            Fixtures.account(name: "Family", index: 1, type: .joint, tokens: jointTokens),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        #expect(accounts[1].tokens == jointTokens)
        #expect(accounts[0].tokens.isEmpty)
        #expect(!result.isRedistributionHappened)
    }

    @Test("An account of each kind sharing a derivation index keeps its own tokens")
    func kindsSharingAnIndexKeepTheirTokensApart() throws {
        let jointTokens = [try Fixtures.token("ltc", at: "m/44'/0'/1'/0/0")]
        var accounts = [
            try Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc", at: "m/44'/0'/1'/0/0")]),
            Fixtures.account(name: "Savings", index: 1),
            Fixtures.account(name: "Family", index: 1, type: .joint, tokens: jointTokens),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(in: &accounts)

        // The token names account 1, and only the wallet's own account of that number receives it
        #expect(accounts[1].tokens.map(\.name) == ["btc"])
        #expect(accounts[2].tokens == jointTokens)
        #expect(result.isRedistributionHappened)
    }

    // MARK: - Tokens the wallet carries over from its legacy list

    @Test("An unassigned token is placed in the account its path names")
    func unassignedTokenIsPlacedByItsPath() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &accounts,
            additionalTokens: [try Fixtures.token("btc", at: "m/44'/0'/1'/0/0")]
        )

        #expect(accounts[0].tokens.isEmpty)
        #expect(accounts[1].tokens.map(\.name) == ["btc"])
        #expect(result.isRedistributionHappened)
    }

    @Test("An unassigned token with no derivation path at all goes to the Main account")
    func pathlessUnassignedTokenGoesToMain() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &accounts,
            additionalTokens: [Fixtures.pathlessToken("btc")]
        )

        #expect(accounts[0].tokens.map(\.name) == ["btc"])
        #expect(accounts[1].tokens.isEmpty)
        #expect(result.isRedistributionHappened)
    }

    @Test("An unassigned token never lands in a joint account, whatever derivation node it names")
    func unassignedTokenNeverLandsInAJointAccount() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            Fixtures.account(name: "Family", index: 2, type: .joint),
        ]

        // Names the derivation node the joint account is numbered by, which the wallet has no own account for
        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &accounts,
            additionalTokens: [try Fixtures.token("btc", at: "m/44'/0'/2'/0/0")]
        )

        #expect(accounts[0].tokens.map(\.name) == ["btc"])
        #expect(accounts[1].tokens.isEmpty)
        #expect(result.isRedistributionHappened)
    }

    @Test("An unassigned token derived at a joint account's path is left alone, whatever number it reads as")
    func unassignedJointTokenIsLeftAlone() throws {
        var accounts = [
            Fixtures.account(name: "Main", index: 0),
            // The account the joint path would be filed under, were it read by the scheme of the wallet's own accounts
            Fixtures.account(name: "Savings", index: 1),
        ]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &accounts,
            additionalTokens: [Fixtures.jointToken("eth", accountIndex: 1)]
        )

        #expect(accounts[0].tokens.isEmpty)
        #expect(accounts[1].tokens.isEmpty)
        #expect(!result.isRedistributionHappened)
    }

    @Test("An unassigned token comes from outside the accounts, and is reported as such")
    func unassignedTokenIsReportedAsExternal() throws {
        var accounts = [Fixtures.account(name: "Main", index: 0)]

        let result = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &accounts,
            additionalTokens: [Fixtures.pathlessToken("btc")]
        )

        guard case .redistributionHappened(let pairs) = result else {
            Issue.record("Expected a redistribution to be reported")
            return
        }

        #expect(pairs.first?.source == .external)
        #expect(pairs.first?.toAccountName == "Main")
    }
}

// MARK: - Fixtures

private extension StoredCryptoAccountsTokensDistributorTests {
    enum Fixtures {
        static func account(
            name: String,
            index: Int,
            type: AccountType = .crypto,
            tokens: [StoredCryptoAccount.Token] = []
        ) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: index,
                type: type,
                name: name,
                icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
                tokens: tokens,
                grouping: .none,
                sorting: .manual
            )
        }

        /// - Parameter rawPath: A Bitcoin path, whose third node names the account the token belongs to.
        static func token(_ name: String, at rawPath: String) throws -> StoredCryptoAccount.Token {
            let derivationPath = try DerivationPath(rawPath: rawPath)

            return makeToken(name, blockchainNetwork: .known(blockchainNetwork: .init(
                blockchain: .bitcoin(testnet: false),
                derivationPath: derivationPath,
                settings: nil
            )))
        }

        /// A token derived where a joint account holds everything of an EVM network.
        static func jointToken(_ name: String, accountIndex: Int) -> StoredCryptoAccount.Token {
            makeToken(name, blockchainNetwork: .known(blockchainNetwork: .init(
                blockchain: .ethereum(testnet: false),
                derivationPath: JointAccountKeyPath.derivationPath(forAccountAtIndex: accountIndex),
                settings: nil
            )))
        }

        /// A token added before the wallets supported derivation at all.
        static func pathlessToken(_ name: String) -> StoredCryptoAccount.Token {
            makeToken(name, blockchainNetwork: .known(blockchainNetwork: .init(
                blockchain: .bitcoin(testnet: false),
                derivationPath: nil,
                settings: nil
            )))
        }

        /// A token of a network this version of the app knows nothing about.
        static func unsupportedToken(_ name: String) -> StoredCryptoAccount.Token {
            makeToken(name, blockchainNetwork: .unknown(networkId: "mystery-network", rawDerivationPath: nil))
        }

        private static func makeToken(
            _ name: String,
            blockchainNetwork: StoredCryptoAccount.Token.BlockchainNetworkContainer
        ) -> StoredCryptoAccount.Token {
            StoredCryptoAccount.Token(
                id: name,
                name: name,
                symbol: name.uppercased(),
                decimalCount: 8,
                blockchainNetwork: blockchainNetwork,
                contractAddress: nil
            )
        }
    }
}
