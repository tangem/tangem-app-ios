//
//  ForYouAccountSelectorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemTestKit
@testable import Tangem

@Suite("ForYouAccountSelectorViewModel")
@MainActor
final class ForYouAccountSelectorViewModelTests: LeakTrackingTestSuite {
    typealias SUT = ForYouAccountSelectorViewModel

    // MARK: - Seed

    @Test("`.all` seeds every account as checked")
    func allSeedsEverything() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, secondAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all)

        #expect(sut.selectedAccountIDs == ids(of: [firstAccount, secondAccount]))
    }

    @Test("A live subset seeds only its ids")
    func liveSubsetSeedsItsIds() {
        let firstAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .subset([ForYouAccountID(firstAccount)]))

        #expect(sut.selectedAccountIDs == ids(of: [firstAccount]))
    }

    @Test("A fully stale subset seeds every account (fallback)")
    func fullyStaleSubsetSeedsEverything() {
        let firstAccount = anyAccount
        // staleAccount's id is in the selection, but the account itself is not in the wallet set — as if it was removed.
        let staleAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount])
        let sut = makeSUT(wallets: [wallet], selection: .subset([ForYouAccountID(staleAccount)]))

        #expect(sut.selectedAccountIDs == ids(of: [firstAccount]))
    }

    @Test("A partially stale subset seeds only its living ids")
    func partiallyStaleSubsetSeedsLivingIds() {
        let firstAccount = anyAccount
        let staleAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, anyAccount])
        let accountIDs: Set<ForYouAccountID> = [ForYouAccountID(firstAccount), ForYouAccountID(staleAccount)]
        let sut = makeSUT(wallets: [wallet], selection: .subset(accountIDs))

        #expect(sut.selectedAccountIDs == ids(of: [firstAccount]))
    }

    // MARK: - Sections

    @Test("A wallet without accounts produces no section")
    func walletWithoutAccountsIsSkipped() {
        let walletWithAccount = makeWallet(id: "walletWithAccounts", accounts: [anyAccount])
        let sut = makeSUT(wallets: [walletWithAccount, anyWallet])

        #expect(sut.sections.count == 1)
        #expect(sut.sections.first?.walletId == walletWithAccount.userWalletId.stringValue)
    }

    @Test("A section mirrors its wallet's identity and accounts")
    func sectionMirrorsWallet() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let wallet = makeWallet(name: "Family", accounts: [firstAccount, secondAccount])
        let sut = makeSUT(wallets: [wallet])
        let section = sut.sections[0]

        #expect(section.walletId == wallet.userWalletId.stringValue)
        #expect(section.walletName == "Family")
        #expect(Set(section.accounts.map(\.id)) == ids(of: [firstAccount, secondAccount]))
    }

    @Test("Sections mirror every wallet that has accounts, in order")
    func sectionsMirrorEveryWallet() {
        let firstWallet = makeWallet(id: "first", name: "First", accounts: [anyAccount])
        let secondWallet = makeWallet(id: "second", name: "Second", accounts: [anyAccount, anyAccount])
        let sut = makeSUT(wallets: [firstWallet, secondWallet])

        #expect(sut.sections.map(\.walletId) == [firstWallet.userWalletId.stringValue, secondWallet.userWalletId.stringValue])
        #expect(sut.sections.map(\.walletName) == ["First", "Second"])
        #expect(sut.sections.map { $0.accounts.count } == [1, 2])
    }

    // MARK: - canApply

    @Test("canApply is false only when nothing is selected")
    func canApplyReflectsSelection() {
        let wallet = makeWallet(accounts: [anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all)

        #expect(sut.canApply)

        sut.sections[0].accounts[0].rowViewModel.onSelect()

        #expect(!sut.canApply)
    }

    // MARK: - isWalletFullySelected

    @Test("isWalletFullySelected tracks partial vs full selection")
    func isWalletFullySelectedTracksState() {
        let wallet = makeWallet(accounts: [anyAccount, anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all)
        let section = sut.sections[0]

        #expect(sut.isWalletFullySelected(section))

        sut.sections[0].accounts[0].rowViewModel.onSelect()

        #expect(!sut.isWalletFullySelected(section))
    }

    @Test("An empty section is never fully selected")
    func emptySectionNeverFullySelected() {
        let wallet = makeWallet(accounts: [anyAccount])
        let sut = makeSUT(wallets: [wallet])
        let empty = ForYouAccountSelectorSection(walletId: "x", walletName: "X", walletThumbnailType: nil, accounts: [])

        #expect(!sut.isWalletFullySelected(empty))
    }

    // MARK: - Toggling

    @Test("toggleWallet clears a fully-selected wallet and restores it")
    func toggleWalletClearsAndRestores() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, secondAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all)
        let section = sut.sections[0]

        sut.toggleWallet(section)
        #expect(sut.selectedAccountIDs.isEmpty)

        sut.toggleWallet(section)
        #expect(sut.selectedAccountIDs == ids(of: [firstAccount, secondAccount]))
    }

    @Test("toggleWallet on a partially selected wallet selects all its accounts")
    func toggleWalletOnPartiallySelectedSelectsAll() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let wallet = makeWallet(accounts: [firstAccount, secondAccount])
        let sut = makeSUT(wallets: [wallet], selection: .subset([ForYouAccountID(firstAccount)]))
        let section = sut.sections[0]

        #expect(!sut.isWalletFullySelected(section))

        sut.toggleWallet(section)

        #expect(sut.isWalletFullySelected(section))
        #expect(sut.selectedAccountIDs == ids(of: [firstAccount, secondAccount]))
    }

    @Test("Tapping an account row toggles that single account")
    func accountRowTogglesSingleAccount() {
        let wallet = makeWallet(accounts: [anyAccount, anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all)
        let item = sut.sections[0].accounts[0]

        item.rowViewModel.onSelect()
        #expect(!sut.isAccountSelected(item.id))

        item.rowViewModel.onSelect()
        #expect(sut.isAccountSelected(item.id))
    }

    // MARK: - apply

    @Test("Applying a full selection collapses to symbolic `.all`")
    func applyFullSelectionCollapsesToAll() {
        let recorder = ForYouSelectorActionRecorder()
        let wallet = makeWallet(accounts: [anyAccount, anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all, includesAllWallets: true, recorder: recorder)

        sut.apply()

        #expect(recorder.appliedSelections == [.all])
        #expect(recorder.dismissCallCount == 1)
    }

    @Test("A full selection stays a subset while a wallet is locked")
    func applyFullSelectionKeepsSubsetWhenWalletLocked() {
        let firstAccount = anyAccount
        let secondAccount = anyAccount
        let recorder = ForYouSelectorActionRecorder()
        let wallet = makeWallet(accounts: [firstAccount, secondAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all, includesAllWallets: false, recorder: recorder)

        sut.apply()

        #expect(recorder.appliedSelections == [.subset(ids(of: [firstAccount, secondAccount]))])
    }

    @Test("Applying a partial selection stores it as a subset")
    func applyPartialSelectionStoresSubset() {
        let recorder = ForYouSelectorActionRecorder()
        let wallet = makeWallet(accounts: [anyAccount, anyAccount])
        let sut = makeSUT(wallets: [wallet], selection: .all, recorder: recorder)

        sut.sections[0].accounts[0].rowViewModel.onSelect()
        sut.apply()

        let expected = sut.selectedAccountIDs
        #expect(recorder.appliedSelections == [.subset(expected)])
        #expect(recorder.dismissCallCount == 1)
    }

    // MARK: - close

    @Test("close dismisses without applying anything")
    func closeDismissesWithoutApplying() {
        let recorder = ForYouSelectorActionRecorder()
        let wallet = makeWallet(accounts: [anyAccount])
        let sut = makeSUT(wallets: [wallet], recorder: recorder)

        sut.close()

        #expect(recorder.dismissCallCount == 1)
        #expect(recorder.appliedSelections.isEmpty)
    }
}

// MARK: - Helpers

private extension ForYouAccountSelectorViewModelTests {
    var anyWallet: ForYouWalletModelStub {
        makeWallet()
    }

    var anyAccount: CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }

    func makeSUT(
        wallets: [any UserWalletModel],
        selection: ForYouAccountSelection = .all,
        includesAllWallets: Bool = true,
        recorder: ForYouSelectorActionRecorder = ForYouSelectorActionRecorder()
    ) -> SUT {
        let sut = SUT(
            userWalletModels: wallets,
            selection: selection,
            includesAllWallets: includesAllWallets,
            applySelectionAction: recorder.apply,
            dismissAction: recorder.dismiss
        )
        return trackForMemoryLeaks(sut)
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

    func ids(of accounts: [any CryptoAccountModel]) -> Set<ForYouAccountID> {
        Set(accounts.map(ForYouAccountID.init))
    }
}
