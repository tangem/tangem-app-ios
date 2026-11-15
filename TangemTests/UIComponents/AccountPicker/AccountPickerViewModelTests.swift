//
//  AccountPickerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemTestKit
import TangemAccounts
import TangemFoundation
import TangemLocalization
@testable import Tangem

@Suite("AccountPickerViewModel", .timeLimit(.minutes(1)))
@MainActor
final class AccountPickerViewModelTests: LeakTrackingTestSuite {
    @Test("With accounts off every user wallet is a row under the wallet title, locked ones included")
    func singleStateShowsUserWalletRows() async {
        let first = makeUserWallet("first")
        let locked = makeLockedUserWalletModel(idSeed: "locked")
        let empty = makeUserWallet("empty")
        let last = makeUserWallet("last")
        let (sut, _) = await makeSUT(
            userWallets: [userWallet(first), AccountPickerUserWallet(userWalletModel: locked, accounts: []), AccountPickerUserWallet(userWalletModel: empty, accounts: []), userWallet(last)],
            globalState: .single
        )

        let items = await userWalletItems(of: sut) { $0.count == 3 }

        #expect(items.map(\.id) == [first.userWalletId, locked.userWalletId, last.userWalletId])
        let expectedAvailabilities: [SelectorAvailability] = [.available, .locked, .available]
        #expect(items.map(\.availability) == expectedAvailabilities)
        #expect(sut.title == Localization.commonChooseWallet)
    }

    @Test("Selecting a user wallet row hands its account and the user wallet to onSelect")
    func selectingUserWalletRowSelectsItsAccount() async throws {
        let account = makeAccount(isMain: true)
        let userWallet = makeUserWallet("userWallet")
        let (sut, spy) = await makeSUT(userWallets: [AccountPickerUserWallet(userWalletModel: userWallet, accounts: [account])], globalState: .single)

        let item = try #require(await userWalletItems(of: sut) { $0.count == 1 }.first)
        sut.select(item)

        #expect(spy.selections == [Selection(accountId: account.id.toAnyHashable(), userWalletId: userWallet.userWalletId)])
    }

    @Test("Selecting a locked user wallet row does nothing")
    func selectingLockedUserWalletRowDoesNothing() async throws {
        let locked = makeUserWallet("locked", isLocked: true)
        let (sut, spy) = await makeSUT(userWallets: [userWallet(locked)], globalState: .single)

        let item = try #require(await userWalletItems(of: sut) { $0.count == 1 }.first)
        sut.select(item)

        #expect(item.availability == .locked)
        #expect(spy.selections.isEmpty)
        #expect(spy.unavailableSelections.isEmpty)
    }

    @Test("With accounts on every unlocked user wallet is a card with a header under the account title")
    func multipleStateShowsAccountCards() async {
        let first = makeUserWallet("first")
        let lockedStub = makeUserWallet("lockedStub", isLocked: true)
        let locked = makeLockedUserWalletModel(idSeed: "locked")
        let last = makeUserWallet("last")
        let (sut, _) = await makeSUT(
            userWallets: [userWallet(first), userWallet(lockedStub), AccountPickerUserWallet(userWalletModel: locked, accounts: []), userWallet(last)],
            globalState: .multiple
        )

        let sections = await sections(of: sut) { $0.count == 2 }

        #expect(sections.map(\.id) == [first.userWalletId.stringValue, last.userWalletId.stringValue])
        #expect(sections.map { $0.header?.name } == [first.name, last.name])
        #expect(sut.title == Localization.commonChooseAccount)
    }

    @Test("A single user wallet card has no header")
    func singleCardHasNoHeader() async throws {
        let (sut, _) = await makeSUT(userWallets: [userWallet(makeUserWallet("userWallet"))], globalState: .multiple)

        let section = try #require(await sections(of: sut) { $0.count == 1 }.first)

        #expect(section.header == nil)
    }

    @Test("An account row shows its tokens, its balance and a Joint badge for joint accounts")
    func accountRowShowsDetails() async throws {
        let balanceSubject = CurrentValueSubject<TotalBalanceState, Never>(.loaded(balance: 42))
        let cryptoAccount = makeAccount(isMain: true, totalBalanceProvider: TotalBalanceProviderStub(subject: balanceSubject))
        let jointAccount = makeAccount(isMain: false, accountType: .joint)
        let (sut, _) = await makeSUT(
            userWallets: [AccountPickerUserWallet(userWalletModel: makeUserWallet("userWallet"), accounts: [cryptoAccount, jointAccount])],
            globalState: .multiple
        )

        let expectedBalance = SelectorBalance.loaded(BalanceFormatter().formatFiatBalance(42, currencyCode: AppSettings.shared.selectedCurrencyCode))
        let accounts = try #require(await sections(of: sut) { $0.first?.accounts.first?.balance == expectedBalance }.first?.accounts)

        #expect(accounts.map(\.badge) == [nil, Localization.commonJoint])
        #expect(accounts.first?.subtitle == "\(Localization.commonTokensCount(0)) \(AppConstants.dotSign)")
    }

    @Test("Selecting an available account hands it to onSelect and moves the checkmark")
    func selectingAvailableAccountMovesCheckmark() async throws {
        let userWallet = makeUserWallet("userWallet")
        let first = makeAccount(isMain: true)
        let second = makeAccount(isMain: false)
        let (sut, spy) = await makeSUT(
            userWallets: [AccountPickerUserWallet(userWalletModel: userWallet, accounts: [first, second])],
            globalState: .multiple,
            selectedAccount: first
        )

        let accounts = try #require(await sections(of: sut) { $0.count == 1 }.first?.accounts)
        #expect(accounts.map(\.isSelected) == [true, false])

        sut.select(accounts[1])

        #expect(spy.selections == [Selection(accountId: second.id.toAnyHashable(), userWalletId: userWallet.userWalletId)])
        #expect(currentSections(of: sut).first?.accounts.map(\.isSelected) == [false, true])
    }

    @Test("Tapping an unavailable account reports it with its reason to onUnavailableSelect and doesn't select it")
    func tappingUnavailableAccountReportsIt() async throws {
        let userWallet = makeUserWallet("userWallet")
        let account = makeAccount(isMain: true)
        let reason = SelectorUnavailableReason(badge: nil, title: "title", message: "message")
        let (sut, spy) = await makeSUT(
            userWallets: [AccountPickerUserWallet(userWalletModel: userWallet, accounts: [account])],
            globalState: .multiple,
            accountAvailabilityProvider: AccountAvailabilityProviderStub(availability: .unavailable(reason))
        )

        let item = try #require(await sections(of: sut) { $0.count == 1 }.first?.accounts.first)
        sut.select(item)

        #expect(item.availability == .unavailable(reason))
        #expect(spy.selections.isEmpty)
        #expect(spy.unavailableSelections == [UnavailableSelection(selection: Selection(accountId: account.id.toAnyHashable(), userWalletId: userWallet.userWalletId), reason: reason)])
        #expect(currentSections(of: sut).first?.accounts.map(\.isSelected) == [false])
    }

    @Test("A preselected account that is unavailable isn't checked")
    func unavailablePreselectedAccountIsNotChecked() async throws {
        let account = makeAccount(isMain: true)
        let reason = SelectorUnavailableReason(badge: nil, title: "title", message: "message")
        let (sut, _) = await makeSUT(
            userWallets: [AccountPickerUserWallet(userWalletModel: makeUserWallet("userWallet"), accounts: [account])],
            globalState: .multiple,
            accountAvailabilityProvider: AccountAvailabilityProviderStub(availability: .unavailable(reason)),
            selectedAccount: account
        )

        let accounts = try #require(await sections(of: sut) { $0.count == 1 }.first?.accounts)

        #expect(accounts.map(\.isSelected) == [false])
    }

    @Test("The layout and title follow the accounts state while the picker is open")
    func layoutFollowsAccountsState() async throws {
        let globalStateProvider = SelectorCryptoAccountsGlobalStateProviderStub(state: .single)
        let userWallet = makeUserWallet("userWallet")
        let (sut, _) = await makeSUT(userWallets: [self.userWallet(userWallet)], globalState: .single, globalStateProvider: globalStateProvider)

        _ = await userWalletItems(of: sut) { $0.count == 1 }
        #expect(sut.title == Localization.commonChooseWallet)

        globalStateProvider.send(.multiple)
        let sections = await sections(of: sut) { $0.count == 1 }

        #expect(sections.map(\.id) == [userWallet.userWalletId.stringValue])
        #expect(sut.title == Localization.commonChooseAccount)
    }

    @Test("An unavailable user wallet makes every account in it unavailable")
    func unavailableUserWalletMakesAccountsUnavailable() async throws {
        let reason = SelectorUnavailableReason(badge: "Full", title: "title", message: "message")
        let (sut, spy) = await makeSUT(
            userWallets: [AccountPickerUserWallet(userWalletModel: makeUserWallet("userWallet"), accounts: [makeAccount(isMain: true), makeAccount(isMain: false)])],
            globalState: .multiple,
            userWalletAvailabilityProvider: UserWalletAvailabilityProviderStub(availability: .unavailable(reason))
        )

        let accounts = try #require(await sections(of: sut) { $0.count == 1 }.first?.accounts)
        sut.select(accounts[0])

        let expectedAvailabilities: [SelectorAvailability] = [.unavailable(reason), .unavailable(reason)]
        #expect(accounts.map(\.availability) == expectedAvailabilities)
        #expect(spy.selections.isEmpty)
        #expect(spy.unavailableSelections.map(\.reason) == [reason])
    }
}

// MARK: - Helpers

private extension AccountPickerViewModelTests {
    func makeSUT(
        userWallets: [AccountPickerUserWallet],
        globalState: CryptoAccounts.State,
        globalStateProvider: SelectorCryptoAccountsGlobalStateProviderStub? = nil,
        accountAvailabilityProvider: any AccountPickerAccountAvailabilityProvider = .allAvailable(),
        userWalletAvailabilityProvider: any UserWalletSelectorAvailabilityProvider = .lockState(),
        selectedAccount: (any BaseAccountModel)? = nil
    ) async -> (AccountPickerViewModel, SelectionSpy) {
        let spy = SelectionSpy()
        let sut = await withSelectorDependencies(userWalletModels: [], globalState: globalState, globalStateProvider: globalStateProvider) {
            AccountPickerViewModel(
                userWalletsProvider: UserWalletsProviderStub(userWallets: userWallets),
                accountAvailabilityProvider: accountAvailabilityProvider,
                userWalletAvailabilityProvider: userWalletAvailabilityProvider,
                selectedAccount: selectedAccount,
                onSelect: spy.recordSelection,
                onUnavailableSelect: spy.recordUnavailableSelection
            )
        }

        trackForMemoryLeaks(spy)
        return (trackForMemoryLeaks(sut), spy)
    }

    func userWalletItems(of sut: AccountPickerViewModel, until condition: @escaping ([UserWalletSelectorItem]) -> Bool) async -> [UserWalletSelectorItem] {
        await sut.$content.bufferedValues
            .compactMap { content -> [UserWalletSelectorItem]? in
                guard case .userWallets(let items) = content else { return nil }
                return items
            }
            .first(where: condition) ?? []
    }

    func sections(
        of sut: AccountPickerViewModel,
        until condition: @escaping ([AccountPickerUserWalletSection]) -> Bool
    ) async -> [AccountPickerUserWalletSection] {
        await sut.$content.bufferedValues
            .compactMap { content -> [AccountPickerUserWalletSection]? in
                guard case .accounts(let sections) = content else { return nil }
                return sections
            }
            .first(where: condition) ?? []
    }

    func currentSections(of sut: AccountPickerViewModel) -> [AccountPickerUserWalletSection] {
        guard case .accounts(let sections) = sut.content else { return [] }
        return sections
    }

    func userWallet(_ userWalletModel: SelectorUserWalletModelStub) -> AccountPickerUserWallet {
        AccountPickerUserWallet(userWalletModel: userWalletModel, accounts: [makeAccount(isMain: true)])
    }

    func makeAccount(
        isMain: Bool,
        accountType: AccountType = .crypto,
        totalBalanceProvider: TotalBalanceProvider = TotalBalanceProviderMock()
    ) -> CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: isMain, accountType: accountType, totalBalanceProvider: totalBalanceProvider, onArchive: { _ in })
    }

    func makeUserWallet(_ idSeed: String, isLocked: Bool = false) -> SelectorUserWalletModelStub {
        SelectorUserWalletModelStub(idSeed: idSeed, isLocked: isLocked, accountModelsManager: SelectorAccountModelsManagerStub(accountModels: []))
    }
}

// MARK: - Stubs

private struct UserWalletsProviderStub: AccountPickerUserWalletsProvider {
    let userWallets: [AccountPickerUserWallet]

    var userWalletsPublisher: AnyPublisher<[AccountPickerUserWallet], Never> {
        .just(output: userWallets)
    }
}

private struct AccountAvailabilityProviderStub: AccountPickerAccountAvailabilityProvider {
    let availability: SelectorAvailability

    func availability(of account: some BaseAccountModel, in userWalletModel: some UserWalletModel) -> SelectorAvailability {
        availability
    }
}

private struct UserWalletAvailabilityProviderStub: UserWalletSelectorAvailabilityProvider {
    let availability: SelectorAvailability

    func availability(of userWalletModel: any UserWalletModel) -> SelectorAvailability {
        availability
    }
}

private struct TotalBalanceProviderStub: TotalBalanceProvider {
    let subject: CurrentValueSubject<TotalBalanceState, Never>

    var totalBalance: TotalBalanceState { subject.value }
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { subject.eraseToAnyPublisher() }
}

private struct Selection: Equatable {
    let accountId: AnyHashable
    let userWalletId: UserWalletId
}

private struct UnavailableSelection: Equatable {
    let selection: Selection
    let reason: SelectorUnavailableReason
}

private final class SelectionSpy {
    private(set) var selections: [Selection] = []
    private(set) var unavailableSelections: [UnavailableSelection] = []

    func recordSelection(_ selection: AccountPickerSelection) {
        selections.append(Selection(selection))
    }

    func recordUnavailableSelection(_ selection: AccountPickerSelection, reason: SelectorUnavailableReason) {
        unavailableSelections.append(UnavailableSelection(selection: Selection(selection), reason: reason))
    }
}

private extension Selection {
    init(_ selection: AccountPickerSelection) {
        self.init(accountId: selection.account.id.toAnyHashable(), userWalletId: selection.userWalletModel.userWalletId)
    }
}
