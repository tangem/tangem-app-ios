//
//  ForYouAccountSelectionScopeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("ForYouAccountSelectionResolver.SelectionScope")
struct ForYouAccountSelectionScopeTests {
    typealias SUT = ForYouAccountSelectionResolver.SelectionScope

    // MARK: - selected derivation

    @Test("`.all` selects every account")
    func allSelectsEverything() {
        let all = [anyAccount, anyAccount]
        let sut = makeSUT(all: all, selection: .all)

        #expect(selectedIDs(of: sut) == ids(of: all))
        #expect(sut.coversAllAccounts)
        #expect(!sut.isRedundantSubset)
    }

    @Test("A live subset selects only its matching accounts")
    func liveSubsetSelectsOnlyMatchingAccounts() {
        let firstAccount = anyAccount
        // .subset pins a concrete set of accounts by id; .all is the symbolic "every account".
        let sut = makeSUT(all: [firstAccount, anyAccount], selection: .subset([ForYouAccountID(firstAccount)]))

        #expect(selectedIDs(of: sut) == ids(of: [firstAccount]))
        #expect(!sut.coversAllAccounts)
    }

    @Test("A partially stale subset keeps only the accounts that still exist")
    func partiallyStaleSubsetKeepsOnlyExistingAccounts() {
        let firstAccount = anyAccount
        // staleAccount's id is in the selection, but the account itself is not in the scope — as if it was removed.
        let staleAccount = anyAccount
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(staleAccount)]
        let sut = makeSUT(all: [firstAccount, anyAccount], selection: .subset(accountIDs))

        #expect(selectedIDs(of: sut) == ids(of: [firstAccount]))
        #expect(!sut.coversAllAccounts)
    }

    @Test("A fully stale subset falls back to all accounts")
    func fullyStaleSubsetFallsBackToAll() {
        let all = [anyAccount, anyAccount]
        let staleAccount = anyAccount
        let sut = makeSUT(all: all, selection: .subset([ForYouAccountID(staleAccount)]))

        #expect(selectedIDs(of: sut) == ids(of: all))
        #expect(sut.coversAllAccounts)
    }

    @Test("An empty subset falls back to all accounts")
    func emptySubsetFallsBackToAll() {
        let account = anyAccount
        let sut = makeSUT(all: [account], selection: .subset([]))

        #expect(selectedIDs(of: sut) == ids(of: [account]))
    }

    // MARK: - isRedundantSubset

    @Test("A subset covering every account is redundant when no wallet is locked")
    func subsetCoveringEveryAccountIsRedundant() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let all = [firstAccount, secondAccount]
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(secondAccount)]
        let sut = makeSUT(all: all, selection: .subset(accountIDs), includesAllWallets: true)

        #expect(sut.isRedundantSubset)
    }

    @Test("A subset covering every account is not redundant while a wallet is locked")
    func subsetCoveringEveryAccountNotRedundantWhenWalletLocked() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let all = [firstAccount, secondAccount]
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(secondAccount)]
        let sut = makeSUT(all: all, selection: .subset(accountIDs), includesAllWallets: false)

        #expect(!sut.isRedundantSubset)
    }

    @Test("A partial subset is never redundant")
    func partialSubsetNotRedundant() {
        let firstAccount = anyAccount
        let all = [firstAccount, anyAccount]
        let sut = makeSUT(all: all, selection: .subset([ForYouAccountID(firstAccount)]))

        #expect(!sut.isRedundantSubset)
    }

    @Test("An empty scope is never redundant")
    func emptyScopeNotRedundant() {
        let sut = makeSUT(all: [], selection: .subset([]))

        #expect(!sut.isRedundantSubset)
        #expect(sut.coversAllAccounts)
    }

    @Test("`.all` is never a redundant subset")
    func allIsNotRedundantSubset() {
        let sut = makeSUT(all: [anyAccount], selection: .all)

        #expect(!sut.isRedundantSubset)
    }
}

// MARK: - Private helpers

private extension ForYouAccountSelectionScopeTests {
    var anyAccount: CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }

    func makeSUT(
        all accounts: [any CryptoAccountModel],
        selection: ForYouAccountSelection,
        includesAllWallets: Bool = true
    ) -> SUT {
        let wallet = ForYouWalletModelStub(
            idSeed: "anyID",
            name: "anyName",
            isLocked: false,
            accountModelsManager: ForYouAccountsManagerStub(accounts: accounts)
        )
        let walletAccounts = accounts.map {
            ForYouAccountSelectionResolver.WalletAccount(wallet: wallet, account: $0)
        }
        return SUT(all: walletAccounts, selection: selection, includesAllWallets: includesAllWallets)
    }

    func ids(of accounts: [any CryptoAccountModel]) -> Set<ForYouAccountID> {
        Set(accounts.map(ForYouAccountID.init))
    }

    func selectedIDs(of sut: SUT) -> Set<ForYouAccountID> {
        ids(of: sut.selected.map(\.account))
    }
}
