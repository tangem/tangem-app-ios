//
//  ForYouAccountSelectionResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import Tangem

@Suite("ForYouAccountSelectionResolver")
struct ForYouAccountSelectionResolverTests {
    typealias SUT = ForYouAccountSelectionResolver
    typealias AccountSelectionSubject = CurrentValueSubject<ForYouAccountSelection, Never>

    @Test("unlockedWallets returns only unlocked wallets")
    func unlockedWalletsExcludesLockedOnes() {
        let unlocked = makeWallet(id: "anyUnlockedWalletID", isLocked: false)
        let locked = makeWallet(id: "anyLockedWalletID", isLocked: true)
        let sut = makeSUT(wallets: [unlocked, locked])

        #expect(sut.unlockedWallets.map(\.userWalletId) == [unlocked.userWalletId])
    }

    @Test("includesAllWallets is true only when no wallet is locked")
    func includesAllWalletsReflectsLockState() {
        let unlocked = [anyWallet, anyWallet]
        let sutWithUnlocked = makeSUT(wallets: unlocked)
        let oneLocked = [anyWallet, makeWallet(isLocked: true)]
        let sutWithOneLocked = makeSUT(wallets: oneLocked)

        #expect(sutWithUnlocked.includesAllWallets)
        #expect(!sutWithOneLocked.includesAllWallets)
    }

    // MARK: - Scope stream

    @Test("An empty wallet set emits an empty selection scope instead of hanging")
    func emptyWalletSetEmitsEmptyScope() throws {
        // combineLatest of no publishers never emits, so the guard must return Just([])
        // otherwise the subscriber hangs forever.
        let sutWithNoWallets = makeSUT(wallets: [])
        let scope = try latestScope(from: sutWithNoWallets)

        #expect(scope.all.isEmpty)
        #expect(scope.selected.isEmpty)
    }

    @Test("The scope collects every account from all wallets")
    func scopeCollectsAccountsFromAllWallets() throws {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let thirdAccount = anyAccount
        let firstWallet = makeWallet(accounts: [firstAccount, secondAccount])
        let secondWallet = makeWallet(accounts: [thirdAccount])
        let sut = makeSUT(wallets: [firstWallet, secondWallet])
        let scope = try latestScope(from: sut)

        #expect(allIDs(of: scope) == ids(of: [firstAccount, secondAccount, thirdAccount]))
    }

    @Test("Accounts of a locked wallet are excluded from the scope")
    func scopeExcludesLockedWalletAccounts() throws {
        let accountInUnlockedWallet = anyAccount
        let accountInLockedWallet = anyAccount
        let unlockedWallet = makeWallet(accounts: [accountInUnlockedWallet])
        let lockedWallet = makeWallet(isLocked: true, accounts: [accountInLockedWallet])
        let sut = makeSUT(wallets: [unlockedWallet, lockedWallet])
        let scope = try latestScope(from: sut)

        #expect(allIDs(of: scope) == ids(of: [accountInUnlockedWallet]))
    }

    @Test("Changing the selection updates which accounts are selected")
    func changingSelectionUpdatesSelectedAccounts() throws {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, secondAccount])
        let selectionSubject = AccountSelectionSubject(.all)
        let sut = makeSUT(wallets: [wallet], selectionSubject: selectionSubject)
        let collector = collectScopes(from: sut)

        #expect(selectedIDs(of: try #require(collector.latest)) == ids(of: [firstAccount, secondAccount]))

        // Emulate the user keeping only the first account selected.
        // .subset pins a concrete set of account ids; .all is the symbolic "every account".
        selectionSubject.send(.subset([ForYouAccountID(firstAccount)]))

        #expect(selectedIDs(of: try #require(collector.latest)) == ids(of: [firstAccount]))
    }

    @Test("Adding a wallet brings its accounts into the scope")
    func addingWalletBringsItsAccountsIntoScope() throws {
        let existingAccount = anyAccount
        let newAccount = anyAccount
        let existingWallet = makeWallet(accounts: [existingAccount])
        let repository = ForYouUserWalletRepositoryStub(models: [existingWallet])
        let sut = makeSUT(repository: repository)
        let collector = collectScopes(from: sut)

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [existingAccount]))

        let addedWallet = makeWallet(accounts: [newAccount])
        repository.setModels([existingWallet, addedWallet])
        repository.emit()

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [existingAccount, newAccount]))
    }

    @Test("Adding an account to a wallet brings it into the scope")
    func addingAccountToWalletBringsItIntoScope() throws {
        let existingAccount = anyAccount
        let newAccount = anyAccount
        let accountsManager = ForYouAccountsManagerStub(accounts: [existingAccount])
        let wallet = makeWallet(with: accountsManager)
        let repository = ForYouUserWalletRepositoryStub(models: [wallet])
        let sut = makeSUT(repository: repository)
        let collector = collectScopes(from: sut)

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [existingAccount]))

        accountsManager.setAccounts([existingAccount, newAccount])

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [existingAccount, newAccount]))
    }

    @Test("Removing a wallet drops its accounts from the scope")
    func removingWalletDropsItsAccountsFromScope() throws {
        let stayingAccount = anyAccount
        let removedAccount = anyAccount
        let stayingWallet = makeWallet(accounts: [stayingAccount])
        let removedWallet = makeWallet(accounts: [removedAccount])
        let repository = ForYouUserWalletRepositoryStub(models: [stayingWallet, removedWallet])
        let sut = makeSUT(repository: repository)
        let collector = collectScopes(from: sut)

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [stayingAccount, removedAccount]))

        repository.setModels([stayingWallet])
        repository.emit()

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [stayingAccount]))
    }

    @Test("Removing an account from a wallet drops it from the scope")
    func removingAccountDropsItFromScope() throws {
        let stayingAccount = anyAccount
        let removedAccount = anyAccount
        let accountsManager = ForYouAccountsManagerStub(accounts: [stayingAccount, removedAccount])
        let wallet = makeWallet(with: accountsManager)
        let repository = ForYouUserWalletRepositoryStub(models: [wallet])
        let sut = makeSUT(repository: repository)
        let collector = collectScopes(from: sut)

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [stayingAccount, removedAccount]))

        accountsManager.setAccounts([stayingAccount])

        #expect(allIDs(of: try #require(collector.latest)) == ids(of: [stayingAccount]))
    }
}

// MARK: - Private helpers

private extension ForYouAccountSelectionResolverTests {
    var anyWallet: ForYouWalletModelStub {
        makeWallet()
    }

    var anyAccount: CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }

    func makeSUT(wallets: [any UserWalletModel], selectionSubject: AccountSelectionSubject = .init(.all)) -> SUT {
        makeSUT(repository: ForYouUserWalletRepositoryStub(models: wallets), selectionSubject: selectionSubject)
    }

    func makeSUT(
        repository: ForYouUserWalletRepositoryStub,
        selectionSubject: AccountSelectionSubject = .init(.all)
    ) -> SUT {
        SUT(userWalletRepository: repository, selectionPublisher: selectionSubject.eraseToAnyPublisher())
    }

    func makeWallet(
        id: String = "anyWalletID",
        name: String = "anyName",
        isLocked: Bool = false,
        accounts: [any CryptoAccountModel] = []
    ) -> ForYouWalletModelStub {
        makeWallet(id: id, name: name, isLocked: isLocked, with: ForYouAccountsManagerStub(accounts: accounts))
    }

    func makeWallet(
        id: String = "anyWalletID",
        name: String = "anyName",
        isLocked: Bool = false,
        with accountsManager: ForYouAccountsManagerStub
    ) -> ForYouWalletModelStub {
        ForYouWalletModelStub(idSeed: id, name: name, isLocked: isLocked, accountModelsManager: accountsManager)
    }

    /// Subscribes to the scope stream and keeps every emission available through `latest`.
    func collectScopes(from sut: SUT) -> ScopeCollector {
        let collector = ScopeCollector()
        collector.subscribe(to: sut.selectionScopePublisher)
        return collector
    }

    func latestScope(from sut: SUT) throws -> SUT.SelectionScope {
        try #require(collectScopes(from: sut).latest)
    }

    func ids(of accounts: [any CryptoAccountModel]) -> Set<ForYouAccountID> {
        Set(accounts.map(ForYouAccountID.init))
    }

    /// Every account in the scope's universe. SelectionScope = all available accounts + which ones are selected.
    func allIDs(of scope: SUT.SelectionScope) -> Set<ForYouAccountID> {
        ids(of: scope.all.map(\.account))
    }

    func selectedIDs(of scope: SUT.SelectionScope) -> Set<ForYouAccountID> {
        ids(of: scope.selected.map(\.account))
    }
}

// MARK: - ScopeCollector

/// Subscribes to a scope stream and records every emission, exposing the most recent one via `latest`.
/// Owns the subscription for its lifetime, so a test can assert `latest` after each action without a
/// hand-managed cancellable — releasing the collector cancels the subscription.
private final class ScopeCollector {
    typealias SelectionScope = ForYouAccountSelectionResolver.SelectionScope

    private var cancellable: AnyCancellable?

    private(set) var scopes: [SelectionScope] = []

    var latest: SelectionScope? { scopes.last }

    func subscribe(to publisher: ForYouAccountSelectionResolver.SelectionScopePublisher) {
        cancellable = publisher.sink { [weak self] in self?.scopes.append($0) }
    }
}

// MARK: - ForYouUserWalletRepositoryStub

/// `FakeUserWalletRepository` with a controllable event stream and mutable model list.
private final class ForYouUserWalletRepositoryStub: FakeUserWalletRepository {
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func setModels(_ models: [any UserWalletModel]) {
        self.models = models
    }

    /// Any event triggers a resolver rebuild — the resolver maps the payload to `Void`.
    func emit(_ event: UserWalletRepositoryEvent = .locked) {
        eventSubject.send(event)
    }
}
