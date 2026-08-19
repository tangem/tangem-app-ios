//
//  ForYouAccountSelectorChipViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import TangemTestKit
@testable import Tangem

@Suite("ForYouAccountSelectorChipViewModel")
@MainActor
final class ForYouAccountSelectorChipViewModelTests: LeakTrackingTestSuite {
    typealias SUT = ForYouAccountSelectorChipViewModel
    typealias SelectionScope = ForYouAccountSelectionResolver.SelectionScope

    // MARK: - selectionState mapping

    @Test("A scope covering every account shows the `.all` chip")
    func coveringScopeShowsAll() async {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(secondAccount)]
        let partialScope = makeScope(all: [firstAccount, secondAccount, anyAccount], selection: .subset(accountIDs))
        let subject = CurrentValueSubject<SelectionScope, Never>(partialScope)
        let sut = makeSUT(scopePublisher: subject.eraseToAnyPublisher())

        await waitUntil { sut.selection == .multiple(count: 2) }

        let coveringScope = makeScope(all: [firstAccount, secondAccount, anyAccount], selection: .all)
        subject.send(coveringScope)

        await waitUntil { sut.selection == .all }
    }

    @Test("A single selected account shows its name")
    func singleSelectionShowsName() async {
        let selectedAccount = anyAccount
        let scope = makeScope(all: [selectedAccount, anyAccount], selection: .subset([ForYouAccountID(selectedAccount)]))
        let sut = makeSUT(scopePublisher: Just(scope).eraseToAnyPublisher())

        await waitUntil { sut.selection == .single(name: selectedAccount.name) }
    }

    @Test("Several selected accounts show the count")
    func multipleSelectionShowsCount() async {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(secondAccount)]
        let scope = makeScope(all: [firstAccount, secondAccount, anyAccount], selection: .subset(accountIDs))
        let sut = makeSUT(scopePublisher: Just(scope).eraseToAnyPublisher())

        await waitUntil { sut.selection == .multiple(count: 2) }
    }

    @Test("An empty scope shows the `.all` chip")
    func emptyScopeShowsAll() async {
        let selectedAccount = anyAccount
        let singleScope = makeScope(all: [selectedAccount, anyAccount], selection: .subset([ForYouAccountID(selectedAccount)]))
        let subject = CurrentValueSubject<SelectionScope, Never>(singleScope)
        let sut = makeSUT(scopePublisher: subject.eraseToAnyPublisher())

        await waitUntil { sut.selection == .single(name: selectedAccount.name) }

        let emptyScope = makeScope(all: [], selection: .subset([]))
        subject.send(emptyScope)

        await waitUntil { sut.selection == .all }
    }

    // MARK: - Actions

    @Test("resetSelection forwards to the reset action")
    func resetSelectionForwards() {
        let recorder = ForYouSelectorActionRecorder()
        let sut = makeSUT(resetAction: recorder.reset)

        sut.resetSelection()

        #expect(recorder.resetCallCount == 1)
    }

    @Test("openAccountSelector routes to the router")
    func openAccountSelectorRoutes() {
        let router = ForYouAccountSelectorRoutableSpy()
        let sut = makeSUT(router: router)

        sut.openAccountSelector()

        #expect(router.openAccountSelectorCallCount == 1)
    }
}

// MARK: - Helpers

private extension ForYouAccountSelectorChipViewModelTests {
    func makeSUT(
        scopePublisher: AnyPublisher<SelectionScope, Never> = Empty<SelectionScope, Never>(completeImmediately: false).eraseToAnyPublisher(),
        resetAction: @escaping () -> Void = {},
        router: ForYouAccountSelectorRoutable? = nil
    ) -> SUT {
        let sut = SUT(
            selectionScopePublisher: scopePublisher,
            resetSelectionAction: resetAction,
            router: router
        )
        return trackForMemoryLeaks(sut)
    }

    func makeScope(
        all accounts: [any CryptoAccountModel],
        selection: ForYouAccountSelection,
        includesAllWallets: Bool = true
    ) -> SelectionScope {
        let wallet = ForYouWalletModelStub(
            idSeed: "anyID",
            name: "anyName",
            isLocked: false,
            accountModelsManager: ForYouAccountsManagerStub(accounts: accounts)
        )
        let walletAccounts = accounts.map {
            ForYouAccountSelectionResolver.WalletAccount(wallet: wallet, account: $0)
        }
        return .init(all: walletAccounts, selection: selection, includesAllWallets: includesAllWallets)
    }

    var anyAccount: CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }

    func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

// MARK: - Router spy

@MainActor
private final class ForYouAccountSelectorRoutableSpy: ForYouAccountSelectorRoutable {
    private(set) var openAccountSelectorCallCount = 0

    func openAccountSelector() {
        openAccountSelectorCallCount += 1
    }
}
