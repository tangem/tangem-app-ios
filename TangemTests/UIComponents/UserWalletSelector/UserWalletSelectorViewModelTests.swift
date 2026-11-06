//
//  UserWalletSelectorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
import TangemAccounts
import TangemFoundation
import TangemLocalization
@testable import Tangem

@Suite("UserWalletSelectorViewModel", .timeLimit(.minutes(1)))
@MainActor
final class UserWalletSelectorViewModelTests: LeakTrackingTestSuite {
    @Test("Every user wallet gets a row in the provider order, locked ones included")
    func everyUserWalletGetsRow() {
        let first = makeUserWallet("first")
        let locked = makeLockedUserWalletModel(idSeed: "locked")
        let last = makeUserWallet("last")
        let userWallets: [any UserWalletModel] = [first, locked, last]
        let (sut, _) = makeSUT(userWallets: userWallets)

        #expect(sut.items.map(\.id) == userWallets.map(\.userWalletId))
        let expectedAvailabilities: [SelectorAvailability] = [.available, .locked, .available]
        #expect(sut.items.map(\.availability) == expectedAvailabilities)
        #expect(sut.title == Localization.commonChooseWallet)
    }

    @Test("The row shows the whole user wallet balance")
    func rowShowsWholeUserWalletBalance() async {
        let userWallet = makeUserWallet("userWallet")
        let (sut, _) = makeSUT(userWallets: [userWallet])

        userWallet.totalBalanceSubject.send(.loaded(balance: 42))
        let expected = SelectorBalance.loaded(BalanceFormatter().formatFiatBalance(42, currencyCode: AppSettings.shared.selectedCurrencyCode))
        let balance = await sut.$items.bufferedValues
            .compactMap { $0.first?.balance }
            .first { $0 == expected }

        #expect(balance == expected)
    }

    @Test("Renaming a user wallet updates its row")
    func renamingUserWalletUpdatesRow() async {
        let userWallet = makeUserWallet("userWallet")
        let (sut, _) = makeSUT(userWallets: [userWallet])

        userWallet.rename(to: "Renamed")
        let name = await sut.$items.bufferedValues
            .compactMap { $0.first?.name }
            .first { $0 == "Renamed" }

        #expect(name == "Renamed")
    }

    @Test("The availability provider decides how each row is shown")
    func availabilityProviderDecidesRows() {
        let reason = SelectorUnavailableReason(badge: "Full", title: "title", message: "message")
        let (sut, _) = makeSUT(userWallets: [makeUserWallet("userWallet")], availabilityProvider: AvailabilityProviderStub(availability: .unavailable(reason)))

        let expectedAvailabilities: [SelectorAvailability] = [.unavailable(reason)]
        #expect(sut.items.map(\.availability) == expectedAvailabilities)
    }

    @Test("Selecting an available user wallet calls onSelect")
    func selectingAvailableUserWalletCallsOnSelect() throws {
        let first = makeUserWallet("first")
        let second = makeUserWallet("second")
        let (sut, onSelectSpy) = makeSUT(userWallets: [first, second])

        sut.select(try #require(sut.items.last))

        #expect(onSelectSpy.selectedUserWalletIds == [second.userWalletId])
        #expect(sut.unavailableReason == nil)
    }

    @Test("Selecting an unavailable user wallet shows its reason and doesn't call onSelect")
    func selectingUnavailableUserWalletShowsReason() throws {
        let reason = SelectorUnavailableReason(badge: "Full", title: "title", message: "message")
        let (sut, onSelectSpy) = makeSUT(userWallets: [makeUserWallet("userWallet")], availabilityProvider: AvailabilityProviderStub(availability: .unavailable(reason)))

        sut.select(try #require(sut.items.first))

        #expect(onSelectSpy.selectedUserWalletIds.isEmpty)
        #expect(sut.unavailableReason == reason)
    }

    @Test("Selecting a locked user wallet does nothing")
    func selectingLockedUserWalletDoesNothing() throws {
        let (sut, onSelectSpy) = makeSUT(userWallets: [makeLockedUserWalletModel(idSeed: "locked")])

        sut.select(try #require(sut.items.first))

        #expect(onSelectSpy.selectedUserWalletIds.isEmpty)
        #expect(sut.unavailableReason == nil)
    }

    @Test("A user wallet that fills up becomes unavailable for account creation")
    func userWalletBecomesFullOnAccountsChange() async {
        let manager = SelectorAccountModelsManagerStub(accountModels: [.standard(.single(makeAccount(isMain: true)))])
        let userWallet = SelectorUserWalletModelStub(idSeed: "userWallet", accountModelsManager: manager)
        let (sut, _) = makeSUT(userWallets: [userWallet], availabilityProvider: .accountCreation(.crypto))

        let accounts = (0 ..< AccountModelUtils.maxNumberOfAccounts(for: .crypto)).map { makeAccount(isMain: $0 == 0) }
        manager.send([.standard(.multiple(accounts))])
        userWallet.totalBalanceSubject.send(.loaded(balance: 1))

        let expected = SelectorAvailability.unavailable(.accountsLimitReached(for: .crypto))
        let availability = await sut.$items.bufferedValues
            .compactMap { $0.first?.availability }
            .first { $0 == expected }

        #expect(availability == expected)
    }
}

// MARK: - Helpers

private extension UserWalletSelectorViewModelTests {
    func makeSUT(
        userWallets: [any UserWalletModel],
        availabilityProvider: any UserWalletSelectorAvailabilityProvider = .lockState()
    ) -> (UserWalletSelectorViewModel, OnSelectSpy) {
        let onSelectSpy = OnSelectSpy()
        let sut = UserWalletSelectorViewModel(
            userWalletsProvider: UserWalletsProviderStub(userWalletModels: userWallets),
            availabilityProvider: availabilityProvider,
            onSelect: onSelectSpy.record
        )

        trackForMemoryLeaks(onSelectSpy)
        return (trackForMemoryLeaks(sut), onSelectSpy)
    }

    func makeAccount(isMain: Bool) -> CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: isMain, onArchive: { _ in })
    }

    func makeUserWallet(_ idSeed: String) -> SelectorUserWalletModelStub {
        SelectorUserWalletModelStub(
            idSeed: idSeed,
            accountModelsManager: SelectorAccountModelsManagerStub(accountModels: [.standard(.single(makeAccount(isMain: true)))])
        )
    }
}

// MARK: - Stubs

private struct UserWalletsProviderStub: UserWalletSelectorUserWalletsProvider {
    let userWalletModels: [any UserWalletModel]
}

private struct AvailabilityProviderStub: UserWalletSelectorAvailabilityProvider {
    let availability: SelectorAvailability

    func availability(of userWalletModel: any UserWalletModel) -> SelectorAvailability {
        availability
    }
}

private final class OnSelectSpy {
    private(set) var selectedUserWalletIds: [UserWalletId] = []

    func record(_ userWalletId: UserWalletId) {
        selectedUserWalletIds.append(userWalletId)
    }
}
