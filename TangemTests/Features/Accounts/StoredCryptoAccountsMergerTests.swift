//
//  StoredCryptoAccountsMergerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import enum BlockchainSdk.Blockchain
@testable import Tangem

/// The endpoint answers with the accounts as it knows them, and the merge is what puts that answer over what the
/// wallet already has without losing either.
@Suite("Tests for how `StoredCryptoAccountsMerger` puts the endpoint's accounts over the stored ones")
struct StoredCryptoAccountsMergerTests {
    // MARK: - Matching an account against the stored ones

    @Test("An account the wallet already has is updated in place")
    func knownAccountIsUpdatedInPlace() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let stored = [Fixtures.account(name: "Main", index: 0), Fixtures.account(name: "Savings", index: 1)]

        let merged = merger.merge(oldAccounts: stored, newAccounts: [Fixtures.account(name: "Renamed", index: 1)])

        #expect(merged.accounts.map(\.name) == ["Main", "Renamed"])
        #expect(merged.isDirty)
    }

    @Test("An account the wallet does not have yet is appended")
    func unknownAccountIsAppended() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let stored = [Fixtures.account(name: "Main", index: 0)]

        let merged = merger.merge(oldAccounts: stored, newAccounts: [Fixtures.account(name: "Savings", index: 1)])

        #expect(merged.accounts.map(\.name) == ["Main", "Savings"])
        #expect(merged.isDirty)
    }

    @Test("An answer that changes nothing leaves the wallet undisturbed")
    func unchangedAnswerIsNotDirty() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let stored = [Fixtures.account(name: "Main", index: 0), Fixtures.account(name: "Savings", index: 1)]

        let merged = merger.merge(oldAccounts: stored, newAccounts: stored)

        #expect(merged.accounts == stored)
        #expect(!merged.isDirty)
    }

    // MARK: - Accounts of the two kinds sharing a derivation index

    @Test("A joint account is added beside the wallet's own account of the same number, never over it")
    func jointAccountDoesNotOverwriteTheOwnAccountSharingItsIndex() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let ownAccount = Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc")])
        let jointAccount = Fixtures.account(name: "Family", index: 0, type: .joint, tokens: [Fixtures.token("eth")])

        let merged = merger.merge(oldAccounts: [ownAccount], newAccounts: [jointAccount])

        #expect(merged.accounts == [ownAccount, jointAccount])
        #expect(merged.isDirty)
    }

    @Test("A joint account is updated by the joint answer alone, leaving its namesake of the other kind alone")
    func jointAccountIsUpdatedWithoutTouchingTheOtherKind() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let ownAccount = Fixtures.account(name: "Main", index: 0)
        // The joint account comes first on purpose: the wallet's own one must survive whatever the order
        let stored = [Fixtures.account(name: "Family", index: 0, type: .joint), ownAccount]

        let merged = merger.merge(
            oldAccounts: stored,
            newAccounts: [Fixtures.account(name: "Family renamed", index: 0, type: .joint)]
        )

        #expect(merged.accounts.count == 2)
        #expect(merged.accounts[0].name == "Family renamed")
        #expect(merged.accounts[1] == ownAccount)
    }

    // MARK: - Whose tokens win

    @Test("The stored tokens are kept when the merge is told to preserve them")
    func storedTokensArePreserved() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: true)
        let stored = [Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc")])]

        let merged = merger.merge(
            oldAccounts: stored,
            newAccounts: [Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("eth")])]
        )

        #expect(merged.accounts.first?.tokens.map(\.name) == ["btc"])
        // The tokens are the only difference, and they were not taken, so nothing was written
        #expect(!merged.isDirty)
    }

    @Test("The answer's tokens win when the merge is not told to preserve the stored ones")
    func answerTokensWinOtherwise() {
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let stored = [Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("btc")])]

        let merged = merger.merge(
            oldAccounts: stored,
            newAccounts: [Fixtures.account(name: "Main", index: 0, tokens: [Fixtures.token("eth")])]
        )

        #expect(merged.accounts.first?.tokens.map(\.name) == ["eth"])
        #expect(merged.isDirty)
    }
}

// MARK: - Fixtures

private extension StoredCryptoAccountsMergerTests {
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

        static func token(_ name: String) -> StoredCryptoAccount.Token {
            StoredCryptoAccount.Token(
                id: name,
                name: name,
                symbol: name.uppercased(),
                decimalCount: 8,
                blockchainNetwork: .known(blockchainNetwork: .init(
                    blockchain: .bitcoin(testnet: false),
                    derivationPath: nil,
                    settings: nil
                )),
                contractAddress: nil
            )
        }
    }
}
